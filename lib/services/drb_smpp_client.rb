#!/usr/bin/env ruby

# required if using ruby-smpp gem
#gem 'ruby-smpp'
#require 'smpp'

require 'rubygems'
require 'drb'
require 'iconv'
require 'eventmachine'

# use this one if running from Eclipse debugger
#require 'lib/ruby-smpp/smpp'
# use this one if running from DOS console
require (File.join(File.dirname(__FILE__), '..', 'ruby-smpp', 'smpp'))

# DEBUG = true goes to the console, = false to log file
DEBUG = $0 == __FILE__
# set encoding to UTF-8
$KCODE = "U"

# Initialize Ruby on Rails
# MUST pass environment as the first parameter
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
require(File.join(RAILS_ROOT, 'config', 'environment'))

LOG_FILE = "#{RAILS_ROOT}/log/smpp.log"
# if debugging log to the standard output
OUT = if DEBUG then STDOUT else LOG_FILE end

class SmppGateway
  @is_running = false
  
  # The id here is an id of an AOMessage, so in the callback we get the same id
  def send_message(id, from, to, sms)    
    options = {}
    # we first need to detect if the string can be fully encode in latin-1 or ascii so we can use 160 chars
    # notice that non-ascii iso-8859-1 character will be encoded in utf-8
    begin
      if @@use_latin1
        latin1 = convertEncoding('UTF-8', 'ISO-8859-1', sms)
        # can be encoded in latin-1
        @@log.debug "Encoded in ISO-8859-1" 
        options[:data_coding] = 3 # 3 for Latin-1 and 8 for UCS-2
        sms = latin1
      else
        ascii = convertEncoding('UTF-8', 'ASCII', sms)
        # can be encoded in ascii
        @@log.debug "Encoded in ASCII" 
        options[:data_coding] = 0 # 0 for SMSC default (usually ASCII)
        sms = ascii      
      end  
    rescue
      # error, cannot be encoded in latin1, has to be encoded in utf-16
      # Smart: little endian, ETL: big endian
      # if 'utf16' is used first 2 bytes will indicate endianness (FFFE or FEFF)
      utf16 = convertEncoding('UTF-8', @@encoding, sms)
      @@log.debug "Encoded in #{@@encoding}"
      options[:data_coding] = 8 # 3 for Latin-1 and 8 for UCS-2
      sms = utf16
    end    
    ar = [ from, to, sms , options]
    @@log.info "Sending MT from #{from} to #{to}: #{sms}"
    @@tx.send_mt(id, *ar)
    return nil
  rescue Exception => e
    return "#{e.class} #{e.message}"
  end
  
  def start(config)
    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    @@log.debug "Connecting to SMSC..."
    
    @is_running = true
    
    while @is_running do
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
    
    # Gateway was stopped
    @@log.debug "SMPP gateway stopped."    
  end
  
  def stop
    @is_running = false
    @@log.debug "Stopping SMPP gateway..."
  end    
  
  # ruby-smpp delegate methods 
  def mo_received(transceiver, source_addr, destination_addr, short_message, data_coding)        
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
    first_octect = short_message[0]
    second_octect = short_message[1]
    if (first_octect == 5 && second_octect == 0)
      # split UDH and SMS
      udh = short_message[0,6]
      sms = short_message[6..short_message.length-1]
      # data_coding == 0 means 'SMSC default alphabet' and == 8 means 'UCS-2'
      if (data_coding == 8)
        sms = convertEncoding('UCS-2', 'UTF-8', sms)
      end
      
      handleCSMS(source_addr, destination_addr, udh, sms)
    else
      # single part SMS, just create and ATMessage
      sms = short_message
      
      # data_coding == 0 means 'SMSC default alphabet' and == 8 means 'UCS-2'
      if (data_coding == 8)
        sms = convertEncoding('UCS-2', 'UTF-8', sms)
      end
      
      createATMessage(@@application_id, source_addr, destination_addr, sms)
    end
    @@log.info "Delegate: mo_received: from #{source_addr} to #{destination_addr}: #{sms}"
  rescue Exception => e
    @@log.error "Error in mo_received: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      @@log.error "Error in mo_received logging: #{e2.class} #{e2.to_s}"
    end
  end

  def delivery_report_received(transceiver, msg_reference, stat, pdu)
    @@log.info "Delegate: delivery_report_received: ref #{msg_reference} stat #{stat} pdu #{pdu.to_yaml}"
    
    # Find message with channel_relative_id
    msg_reference = msg_reference.to_i
    msg = AOMessage.first(:conditions => ['channel_id = ? AND channel_relative_id = ?', @@channel.id, msg_reference])
    if msg.nil?
      @@log.info "AOMessage with channel_relative_id #{msg_reference} not found"
      return
    end
    
    # Reflect in message state
    msg.state = stat == 'DELIVRD' ? 'confirmed' : 'failed'
    msg.save!
    
    @@application.logger.ao_message_status_receieved msg, stat
  rescue Exception => e
    @@log.error "Error in delivery_report_received: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      @@log.error "Error in delivery_report_received logging: #{e2.class} #{e2.to_s}"
    end
  end

  def message_accepted(transceiver, mt_message_id, smsc_message_id)
    @@log.info "Delegate: message_sent: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
    
    # Find message with mt_message_id
    msg = AOMessage.find mt_message_id
    if msg.nil?
      @@log.info "AOMessage with id #{mt_message_id} not found (ref id: #{smsc_message_id})"
      return
    end
    
    # smsc_message_id comes in hexadecimal
    reference_id = smsc_message_id.to_i(16).to_s
    
    # Blank all messages with that reference id in case the reference id is already used
    AOMessage.update_all(['channel_relative_id = ?', nil], ['channel_id = ? AND channel_relative_id = ?', @@channel.id, reference_id])
    
    # And set this message's channel relative id to later look it up
    # in the delivery_report_received method
    msg.channel_relative_id = reference_id
    msg.save!
    
    @@application.logger.ao_message_status_receieved msg, 'ACK'
  rescue Exception => e
    @@log.error "Error in message_accepted: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      @@log.error "Error in message_accepted logging: #{e2.class} #{e2.to_s}"
    end
  end

  def bound(transceiver)
    @@log.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    @@log.warn "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
  # helpers
  
  def convertEncoding(from, to, str)
    begin
      ic = Iconv.new to, from
      converted = ic.iconv str
      return converted
    rescue => e
      # could not convert
      raise e
    end  
  end
  
  def createATMessage(app_id, source_addr, destination_addr, sms)
    msg = ATMessage.new
    msg.from = 'sms://' + source_addr
    msg.to = 'sms://' + destination_addr
    msg.subject = sms
    #msg.body = sms
    # now?
    msg.timestamp = DateTime.now
    
    @@application.accept msg, @@channel
  end
  
  def handleCSMS(source_addr, destination_addr, udh, sms)
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
  
  def logger
    Smpp::Base.logger
  end
end

def stopSMPPGateway()
  @@log.debug 'Trying to stop gateway...'
  @@gw.stop 
  @@log.debug 'Gateway stopped...'
  sleep 6
  @@log.debug 'Trying to stop DRb server...'
  @@drb_server.stop_service
  @@log.debug "DRb server stopped.. #{@@drb_server.alive?}"
end

def startSMPPGateway(channel_id)
  
  @@log = Logger.new OUT
  
  # Uncomment this line to get a lot more debugging information in the log file, if not will go to the console by default
  #Smpp::Base.logger = @@log
  # find Channel and fetch configuration
  channel_id = ARGV[1]
  @@log.debug "Fetching channel with id #{channel_id} from database."
  @@channel = Channel.find channel_id
  @configuration = @@channel.configuration
  @@application_id = @@channel.application_id
  @@application = Application.find @@application_id
  @@use_latin1 = @configuration[:use_latin1] == '1'
  @@encoding = @configuration[:encoding]
  
  config = {
    :host => @configuration[:host],
    :port => @configuration[:port],
    :system_id => @configuration[:user],
    :password => @configuration[:password],
    :system_type => @configuration[:system_type],
    :interface_version => 52,
    :source_ton  => @configuration[:source_ton].to_i,
    :source_npi => @configuration[:source_npi].to_i,
    :destination_ton => @configuration[:destination_ton].to_i,
    :destination_npi => @configuration[:destination_npi].to_i,
    :source_address_range => '',
    :destination_address_range => '',
    :enquire_link_delay_secs => 10
  }  
  @@gw = SmppGateway.new
  
  # start distributed ruby service
  @@log.debug "Starting Distributed Ruby service."
  @@drb_server = DRb.start_service nil, @@gw
  @@log.info "Distributed Ruby service started on URI #{DRb.uri}"
  
  # register in d_rb_processes table so clients can communicate
  # only one record should exist per channel
  @d_rb_process = DRbProcess.find_or_create_by_channel_id @@channel.id
  @d_rb_process.application_id = @@channel.application_id
  @d_rb_process.uri = DRb.uri
  @d_rb_process.save
  
  @@gw.start(config)  
rescue Exception => ex
  if defined?(@@log).nil?
    raise ex
  else
    @@log.fatal "Exception in SMPP Gateway: #{ex} at #{ex.backtrace.join("\n")}"
  end
end

# Start the Gateway
begin
  if $0 == __FILE__
    channel_id = ARGV[1] unless ARGV.empty?  
    startSMPPGateway(channel_id)
  end
rescue => e
  File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + e }
end
