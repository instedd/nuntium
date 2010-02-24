#!/usr/bin/env ruby

# required if using ruby-smpp gem
#gem 'ruby-smpp'
#require 'smpp'

require 'rubygems'
require 'drb'
require 'iconv'
require 'eventmachine'
require 'cache'

# use this one if running from Eclipse debugger
#require 'lib/ruby-smpp/smpp'
# use this one if running from DOS console
require (File.join(File.dirname(__FILE__), '..', '..', 'lib', 'services', 'ruby-smpp', 'smpp'))

# DEBUG = true goes to the console, = false to log file
DEBUG = $0 == __FILE__
# set encoding to UTF-8
$KCODE = "U"

# Initialize Ruby on Rails
# MUST pass environment as the first parameter
$log_path = File.join(File.dirname(__FILE__), '..', '..', 'log', "drb_smpp_client_#{ARGV[1]}.log")
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
require(File.join(RAILS_ROOT, 'config', 'environment'))

class SmppGateway
  @is_running = false
  
  def initialize()
    @mo_cache = Cache.new(nil, nil, 100, 86400)
    @delivery_report_cache = Cache.new(nil, nil, 100, 86400)
  end
  
  # The id here is an id of an AOMessage, so in the callback we get the same id
  def send_message(id, from, to, sms)    
    options = {}
    # we first need to detect if the string can be fully encode in latin-1 or ascii so we can use 160 chars
    # notice that non-ascii iso-8859-1 character will be encoded in utf-8
    begin
      if @@use_latin1
        latin1 = convertEncoding('UTF-8', 'ISO-8859-1', sms)
        # can be encoded in latin-1
        RAILS_DEFAULT_LOGGER.debug "Encoded in ISO-8859-1" 
        options[:data_coding] = 3 # 3 for Latin-1 and 8 for UCS-2
        sms = latin1
      else
        ascii = convertEncoding('UTF-8', 'ASCII', sms)
        # can be encoded in ascii
        RAILS_DEFAULT_LOGGER.debug "Encoded in ASCII" 
        options[:data_coding] = 0 # 0 for SMSC default (usually ASCII)
        sms = ascii      
      end  
    rescue
      # error, cannot be encoded in latin1, has to be encoded in utf-16
      # Smart: little endian, ETL: big endian
      # if 'utf16' is used first 2 bytes will indicate endianness (FFFE or FEFF)
      utf16 = convertEncoding('UTF-8', @@encoding, sms)
      RAILS_DEFAULT_LOGGER.debug "Encoded in #{@@encoding}"
      options[:data_coding] = 8 # 3 for Latin-1 and 8 for UCS-2
      sms = utf16
    end    
    ar = [ from, to, sms , options]
    RAILS_DEFAULT_LOGGER.info "Sending MT from #{from} to #{to}: #{sms}"
    @@tx.send_mt(id, *ar)
    return nil
  rescue Exception => e
    return "#{e.class} #{e.message}"
  end
  
  def start(config)
    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    RAILS_DEFAULT_LOGGER.debug "Connecting to SMSC..."
    
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
      RAILS_DEFAULT_LOGGER.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
    end
    
    # Gateway was stopped
    RAILS_DEFAULT_LOGGER.debug "SMPP gateway stopped."    
  end
  
  def stop
    @is_running = false
    RAILS_DEFAULT_LOGGER.debug "Stopping SMPP gateway..."
  end    
  
  # ruby-smpp delegate methods 
  def mo_received(transceiver, source_addr, destination_addr, short_message, data_coding)
    
    cache_value = source_addr + destination_addr + short_message
    if @mo_cache[cache_value.hash] == cache_value
      @@log.info "Ignoring duplicate message from #{source_addr} to #{destination_addr}: #{short_message}"
      return true
    end
    @mo_cache[cache_value.hash] = cache_value
    
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
    RAILS_DEFAULT_LOGGER.info "Delegate: mo_received: from #{source_addr} to #{destination_addr}: #{sms}"
  rescue Exception => e
    RAILS_DEFAULT_LOGGER.error "Error in mo_received: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      RAILS_DEFAULT_LOGGER.error "Error in mo_received logging: #{e2.class} #{e2.to_s}"
    end
  end

  def delivery_report_received(transceiver, msg_reference, stat, pdu)
    cache_value = msg_reference.to_s + stat
    if @delivery_report_cache[cache_value.hash] == cache_value
      RAILS_DEFAULT_LOGGER.info "Ignoring duplicate delivery report ref #{msg_reference} stat #{stat} pdu #{pdu.to_yaml}"
      return true
    end
    @delivery_report_cache[cache_value.hash] = cache_value
    
    RAILS_DEFAULT_LOGGER.info "Delegate: delivery_report_received: ref #{msg_reference} stat #{stat} pdu #{pdu.to_yaml}"
    
    # Find message with channel_relative_id
    msg_reference = msg_reference.to_i
    msg = AOMessage.first(:conditions => ['channel_id = ? AND channel_relative_id = ?', @@channel.id, msg_reference])
    if msg.nil?
      RAILS_DEFAULT_LOGGER.info "AOMessage with channel_relative_id #{msg_reference} not found"
      return
    end
    
    # Reflect in message state
    msg.state = stat == 'DELIVRD' ? 'confirmed' : 'failed'
    msg.save!
    
    @@application.logger.ao_message_status_receieved msg, stat
  rescue Exception => e
    RAILS_DEFAULT_LOGGER.error "Error in delivery_report_received: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      RAILS_DEFAULT_LOGGER.error "Error in delivery_report_received logging: #{e2.class} #{e2.to_s}"
    end
  end

  def message_accepted(transceiver, mt_message_id, smsc_message_id)
    RAILS_DEFAULT_LOGGER.info "Delegate: message_sent: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
    
    # Find message with mt_message_id
    msg = AOMessage.find mt_message_id
    if msg.nil?
      RAILS_DEFAULT_LOGGER.info "AOMessage with id #{mt_message_id} not found (ref id: #{smsc_message_id})"
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
    RAILS_DEFAULT_LOGGER.error "Error in message_accepted: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      RAILS_DEFAULT_LOGGER.error "Error in message_accepted logging: #{e2.class} #{e2.to_s}"
    end
  end
  
  def message_accepted_with_error(transceiver, mt_message_id, pdu_command_status)
    RAILS_DEFAULT_LOGGER.info "Delegate: message_sent_with_error: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
    
    # Find message with mt_message_id
    msg = AOMessage.find mt_message_id
    if msg.nil?
      RAILS_DEFAULT_LOGGER.info "AOMessage with id #{mt_message_id} not found (pdu_command_status: #{pdu_command_status})"
      return
    end
    
    @@application.logger.ao_message_status_warning msg, "Command Status '#{pdu_command_status}'"
  rescue Exception => e
    RAILS_DEFAULT_LOGGER.error "Error in message_accepted_with_error: #{e.class} #{e.to_s}"
    begin
      @@application.logger.exception_in_channel @@channel, e
    rescue Exception => e2
      RAILS_DEFAULT_LOGGER.error "Error in message_accepted_with_error logging: #{e2.class} #{e2.to_s}"
    end
  end

  def bound(transceiver)
    RAILS_DEFAULT_LOGGER.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    RAILS_DEFAULT_LOGGER.warn "Delegate: transceiver unbound"
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
  RAILS_DEFAULT_LOGGER.debug 'Trying to stop gateway...'
  @@gw.stop 
  RAILS_DEFAULT_LOGGER.debug 'Gateway stopped...'
  sleep 6
  RAILS_DEFAULT_LOGGER.debug 'Trying to stop DRb server...'
  @@drb_server.stop_service
  RAILS_DEFAULT_LOGGER.debug "DRb server stopped.. #{@@drb_server.alive?}"
end

def startSMPPGateway(channel_id)
  # Uncomment this line to get a lot more debugging information in the log file, if not will go to the console by default
  # find Channel and fetch configuration
  #channel_id = ARGV[1]
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
  RAILS_DEFAULT_LOGGER.debug "Starting Distributed Ruby service."
  @@drb_server = DRb.start_service nil, @@gw
  RAILS_DEFAULT_LOGGER.info "Distributed Ruby service started on URI #{DRb.uri}"
  
  # register in d_rb_processes table so clients can communicate
  # only one record should exist per channel
  @d_rb_process = DRbProcess.find_or_create_by_channel_id @@channel.id
  @d_rb_process.application_id = @@channel.application_id
  @d_rb_process.uri = DRb.uri
  @d_rb_process.save
  
  @@gw.start(config)  
rescue Exception => ex
  if defined?(RAILS_DEFAULT_LOGGER).nil?
    raise ex
  else
    RAILS_DEFAULT_LOGGER.fatal "Exception in SMPP Gateway: #{ex} at #{ex.backtrace.join("\n")}"
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
