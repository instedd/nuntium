#!/usr/bin/env ruby

# required if using ruby-smpp gem
require 'rubygems'
require 'smpp'

require 'rubygems'
require 'drb'
require 'iconv'
require 'eventmachine'
require 'cache'

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

Smpp::Base.logger = Rails.logger

class SmppGateway < SmppTransceiverDelegate
  @is_running = false
  
  
  def start(config)
    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    Rails.logger.debug "Connecting to SMSC..."
    
    @is_running = true
    
    while @is_running do
      EventMachine::run do
        @transceiver = EventMachine::connect(
          config[:host], 
          config[:port], 
          Smpp::Transceiver, 
          config, 
          self    # delegate that will receive callbacks on MOs and DRs and other events
        )      
      end
      Rails.logger.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
    end
    
    # Gateway was stopped
    Rails.logger.debug "SMPP gateway stopped."    
  end
  
  def stop
    @is_running = false
    Rails.logger.debug "Stopping SMPP gateway..."
  end    

  def bound(transceiver)
    Rails.logger.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    Rails.logger.warn "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
end

def stopSMPPGateway()
  return if @@stopping
  @@stopping = true
  Rails.logger.debug 'Trying to stop gateway...'
  @@gw.stop 
  Rails.logger.debug 'Gateway stopped...'
  sleep 6
  Rails.logger.debug 'Trying to stop DRb server...'
  DRb.stop_service
  Rails.logger.debug "DRb server stopped.. #{@@drb_server.alive?}"
end

def startSMPPGateway(channel_id)
  # Uncomment this line to get a lot more debugging information in the log file, if not will go to the console by default
  # find Channel and fetch configuration
  #channel_id = ARGV[1]
  @@stopping = false 
  @@channel = Channel.find_by_id channel_id
  
  @configuration = @@channel.configuration
  @@application_id = @@channel.application_id
  @@application = Application.find_by_id @@application_id
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
  @@gw = SmppGateway.new(nil, @@channel)
  
  # start distributed ruby service
  Rails.logger.debug "Starting Distributed Ruby service."
  @@drb_server = DRb.start_service nil, @@gw
  Rails.logger.info "Distributed Ruby service started on URI #{DRb.uri}"
  
  # register in d_rb_processes table so clients can communicate
  # only one record should exist per channel
  @d_rb_process = DRbProcess.find_or_create_by_channel_id @@channel.id
  @d_rb_process.application_id = @@channel.application_id
  @d_rb_process.uri = DRb.uri
  @d_rb_process.save
  
  @@gw.start(config)  
rescue Exception => ex
  if defined?(Rails.logger).nil?
    raise ex
  else
    Rails.logger.fatal "Exception in SMPP Gateway: #{ex} at #{ex.backtrace.join("\n")}"
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
