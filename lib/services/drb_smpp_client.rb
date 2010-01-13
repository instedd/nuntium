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
    
    puts "Sending MT from #{from} to #{to}: #{body}"   
    @@tx.send_mt(@@mt_id, *ar)
  end

  def send_msg(message_id)
    
    # apparently the following line cause the transceiver to unbound
    msg = AOMessage.find message_id
    
    # should we put body, subject or both here?
    #from = msg.from.without_protocol
    #to = msg.to.without_protocol
    
    #ar = [ from, to, msg.body ]
    #ar = [ '301', '85510718266', 'test' ]
    
    #puts "Sending MT from #{from} to #{to}: #{msg.body}"
    @@tx.send_mt(@@mt_id, *ar)
  end
    
  def start(config)
    # The transceiver sends MT messages to the SMSC. It needs a storage with Hash-like
    # semantics to map SMSC message IDs to your own message IDs.
    pdr_storage = {} 

    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    puts "Connecting to SMSC..."
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
      puts "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
    end
  end
  
  # ruby-smpp delegate methods 

  def mo_received(transceiver, source_addr, destination_addr, short_message)
    puts "Delegate: mo_received: from #{source_addr} to #{destination_addr}: #{short_message}"   

    # temporary workaround to cut extra characters we receive from Smart
    l = short_message.length - 6
    sms = short_message[0,l]

    msg = ATMessage.new
    msg.application_id = @@application_id
    msg.from = 'sms://' + source_addr
    msg.to = 'sms://' + destination_addr
    msg.subject = sms
    msg.body = sms
    # now?
    msg.timestamp = DateTime.now
    msg.state = 'queued'
    msg.save
  end

  def delivery_report_received(transceiver, msg_reference, stat, pdu)
    puts "Delegate: delivery_report_received: ref #{msg_reference} stat #{stat} pdu #{pdu}"
  end

  def message_accepted(transceiver, mt_message_id, smsc_message_id)
    puts "Delegate: message_sent: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
  end

  def bound(transceiver)
    puts "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    puts "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
end

# Start the Gateway
begin
  # Initialize Ruby on Rails
  #LOG_FILE = 'C:\\ruby.log'
  #ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  puts "Starting SMPP Gateway."  

  # find Channel and fetch configuration
  channel_id = ARGV[0]
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
  DRb.start_service nil, gw
  puts DRb.uri

  # register in d_rb_processes table so clients can communicate
  # only one record should exist per channel
  @d_rb_process = DRbProcess.find_or_create_by_channel_id @channel.id
  @d_rb_process.application_id = @channel.application_id
  @d_rb_process.uri = DRb.uri
  @d_rb_process.save
  
  gw.start(config)  
rescue Exception => ex
  puts "Exception in SMPP Gateway: #{ex} at #{ex.backtrace.join("\n")}"
end
