#!/usr/bin/env ruby

require 'rubygems'
gem 'ruby-smpp'
require 'smpp'
require 'drb'

class SmppGateway
  
  # MT id counter
  @@mt_id = 0
  
  # expose SMPP transceiver's send_mt method
  def self.send_mt(*args)
    @@mt_id += 1
    @@tx.send_mt(@@mt_id, *args)
  end

  def send_message(from, to, body)
    ar = [ from, to, body ]
    
    @@log.info "Sending MT from #{from} to #{to}: #{body}"   
    @@tx.send_mt(@@mt_id, *ar)
  end

  def send_msg(message_id)
    # apparently the following line cause the transceiver to unbound (in Windows only)
    msg = AOMessage.find message_id
    
    # should we put body, subject or both here?
    from = msg.from.without_protocol
    to = msg.to.without_protocol
    
    ar = [ from, to, msg.body ]
    
    @@log.info "Sending MT from #{from} to #{to}: #{msg.body}"
    @@tx.send_mt(@@mt_id, *ar)
  end
    
  def start(config)
    # The transceiver sends MT messages to the SMSC. It needs a storage with Hash-like
    # semantics to map SMSC message IDs to your own message IDs.
    pdr_storage = {} 

    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    @@log.debug "Connecting to SMSC..."
    loop do
      EventMachine::run do      
        @@tx = EventMachine::connect(
          config[:host], 
          config[:port], 
          Smpp::Transceiver, 
          config, 
          self    # delegate that will receive callbacks on MOs and DRs and other events
        )    
        
      end
      @@log.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
    end
  end
  
  # ruby-smpp delegate methods 

  def mo_received(transceiver, source_addr, destination_addr, short_message)
    @@log.info "Delegate: mo_received: from #{source_addr} to #{destination_addr}: #{short_message}"   
    
    # temporary workaround to cut extra characters we receive from Smart
    l = short_message.length - 6
    sms = short_message[0,l]

=begin

USER DATA HEADER for Concatenated SMS (http://en.wikipedia.org/wiki/Concatenated_SMS)

1st: Length of User Data Header = 5
2nd: Information Element Identifier = 0
3rd: Length of the header, excluding the first two fields = 3
4th: CSMS reference number, must be the same for all the SMS parts
5th: Total number of parts
6th: This part's number in the sequence

=end
    
    # check if it is a CSMS
  
    first_octect = sms[0]
    second_octect = sms[1]
  
    if (first_octect == 5 && second_octect == 0)
      handleCSMS(source_addr, destination_addr, sms)
    else
      # single part SMS, just create and ATMessage
      createATMessage(@@application_id, source_addr, destination_addr, sms)
    end
  end

  def delivery_report_received(transceiver, msg_reference, stat, pdu)
    @@log.info "Delegate: delivery_report_received: ref #{msg_reference} stat #{stat} pdu #{pdu}"
  end

  def message_accepted(transceiver, mt_message_id, smsc_message_id)
    @@log.info "Delegate: message_sent: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
  end

  def bound(transceiver)
    @@log.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    @@log.warn "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
  # helpers
  
  def createATMessage(app_id, source_addr, destination_addr, sms)
      msg = ATMessage.new
      msg.application_id = app_id
      msg.from = 'smpp://' + source_addr
      msg.to = 'smpp://' + destination_addr
      msg.subject = sms
      msg.body = sms
      # now?
      msg.timestamp = DateTime.now
      msg.state = 'queued'
      msg.save
  end
  
  def handleCSMS(source_addr, destination_addr, short_message)
    # split UDH and SMS
    udh = short_message[0,6]
    sms = short_message[6..short_message.length-1]
    
=begin
4th: CSMS reference number, must be the same for all the SMS parts
5th: Total number of parts
6th: This part's number in the sequence  
=end

    # parse UDH relevant fields
    ref = udh[3]
    total = udh[4]
    partn = udh[5]
    
    # check if we have all the parts for this reference number in the database
    conditions = ['reference_number = ?', ref]
    parts = SmppMessagePart.all(:conditions => conditions)
    
    # If all other parts are here
    if parts.length == total-1
      # Add this new part, sort and get text
      parts.push SmppMessagePart.new(:part_number => partn, :text => sms)
      parts.sort! { |x,y| x.part_number <=> y.part_number }
      text = parts.collect { |x| x.text }.to_s
      
      # Create message from the resulting text
      createATMessage(@@application_id, source_addr, destination_addr, text)
            
      # Delete stored information
      SmppMessagePart.delete_all conditions
    else
      # Just save the part
      SmppMessagePart.create(
        :reference_number => ref,
        :part_count => total,
        :part_number => partn,
        :text => sms
        )
    end
    
  end
  
end

# Start the Gateway
begin
  # Initialize Ruby on Rails
  #LOG_FILE = 'log/smpp.log'
  #ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  # log to the standard output for debugging purposes
  @@log = Logger.new(STDOUT)

  # find Channel and fetch configuration
  channel_id = ARGV[0]
  @@log.debug "Fetching channel with id #{channel_id} from database."
  @channel = Channel.find channel_id
  @configuration = @channel.configuration
  @@application_id = @channel.application_id
  
  config = {
    :host => @configuration[:host],
    :port => @configuration[:port],
    :system_id => @configuration[:user],
    :password => @configuration[:password],
    :system_type => 'vma', # default given according to SMPP 3.4 Spec
    :interface_version => 52,
    :source_ton  => 0,
    :source_npi => 1,
    :destination_ton => 0,
    :destination_npi => 1,
    :source_address_range => '',
    :destination_address_range => '',
    :enquire_link_delay_secs => 10
  }  
  gw = SmppGateway.new
  
  # start distributed ruby service
  @@log.debug "Starting Distributed Ruby service."
  DRb.start_service nil, gw
  @@log.info "Distributed Ruby service started on URI #{DRb.uri}"
  
  # register in d_rb_processes table so clients can communicate
  # only one record should exist per channel
  @d_rb_process = DRbProcess.find_or_create_by_channel_id @channel.id
  @d_rb_process.application_id = @channel.application_id
  @d_rb_process.uri = DRb.uri
  @d_rb_process.save
  
  gw.start(config)  
rescue Exception => ex
  @@log.fatal "Exception in SMPP Gateway: #{ex} at #{ex.backtrace.join("\n")}"
end
