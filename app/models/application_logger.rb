class ApplicationLogger
  def initialize(application_id)
    @application_id = application_id
  end
  
  def protocol_not_found_for_ao_message(ao_msg)
    error(:ao_message_id => ao_msg.id, :channel_id => ao_msg.channel_id, :message => "Protocol not found in 'to' field")
  end

  def no_channel_found_for_ao_message(protocol, ao_msg)
    error(:ao_message_id => ao_msg.id, :channel_id => ao_msg.channel_id, :message => "No channel found for protocol '#{protocol}'")
  end
  
  def at_message_delivery_succeeded(msg, interface)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} succeeded")
  end
  
  def at_message_delivery_exceeded_tries(msg, interface)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} exceeded maximum number of tries")
  end
  
  def ao_message_delivery_succeeded(msg, channel)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => 'Try #' + "#{msg.tries} for delivering message through channel #{channel} succeeded")
  end
  
  def ao_message_delivery_exceeded_tries(msg, channel)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => 'Try #' + "#{msg.tries} for delivering message through channel #{channel} exceeded maximum number of tries")
  end
  
  def ao_message_received(msg, interface)
    if interface.class == Hash and interface[:application].class == Application
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received from application '#{interface[:application].name}'")
    elsif interface == 're-route'
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message was re-routed")
    else
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received via #{interface} interface")
    end
  end
  
  def ao_message_handled_by_channel(msg, channel)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message handled by #{channel.kind} channel '#{channel.name}'")
  end
  
  def ao_message_routed_to_application(msg, app)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message routed to application '#{app.name}'")
  end
  
  def ao_message_created_as_alert(msg)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message was created as an alert")
  end
  
  def ao_message_status_receieved(msg, status)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "#{status} received from server")
  end
  
  def ao_message_status_warning(msg, status)
    warning(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "#{status} received from server")
  end
  
  def channel_not_found(msg, channel_name)
    if channel_name.class == Array
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Channels with names '#{channel_name.join('\"')}' do not exist or are disabled")
    else
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Channel with name '#{channel_name}' does not exist or is disabled")
    end
  end
  
  def at_message_received_via_channel(msg, channel)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received via #{channel.kind} channel '#{channel.name}'")
  end
  
  def at_message_received_via(msg, via)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received via #{via}")
  end
  
  def at_message_created_via_ui(msg)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message created via user interface")
  end
  
  def error_routing_msg(ao_msg, e)
    error(:message => "Error routing message '#{e.to_s}'", :ao_message_id => ao_msg.id, :channel_id => ao_msg.channel_id)
  end

  def error_obtaining_last_id(message)
    error(:message => "Error obtaining last id from server in QST operation: '#{message}'")
  end

  def error_initializing_http(exception)
    error(:message => "Error initializing http connection in QST operation: '#{exception_msg(exception)}'")
  end
  
  def error_posting_msgs(msg)
    error(:message => "Error posting messages to server in QST operation: '#{msg}'")
  end
  
  def error_pulling_msgs(msg)
    error(:message => "Error pulling messages from server in QST operation: '#{msg}'")
  end
  
  def error_processing_msgs(msg)
    error(:message => "Error processing messages from server in QST operation: '#{msg}'")
  end

  def more_than_one_channel_found_for(protocol, ao_msg)
    warning(:ao_message_id => ao_msg.id, :message => "More than one channel found for protocol '#{protocol}'", :channel_id => ao_msg.channel_id)
  end
  
  def info(hash_or_message)
    create(hash_or_message, ApplicationLog::Info)
  end
  
  def warning(hash_or_message)
    create(hash_or_message, ApplicationLog::Warning)
  end
  
  def error(hash_or_message)
    create(hash_or_message, ApplicationLog::Error)
  end
  
  def self.exception_in_channel(channel, exception)
    logger = ApplicationLogger.new(channel.application_id)
    logger.error(:channel_id => channel.id, :message => "#{exception_msg(exception)}")
  end
  
  def exception_in_channel_and_ao_message(channel, ao_msg, exception)
    error(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => 'Try #' + "#{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' failed: #{exception_msg(exception)}")
  end
  
  def message_channeled(ao_msg, channel)
    info(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => 'Try #' + "#{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' succeeded")
  end
  
  def create(hash_or_message, severity)
    if hash_or_message.class.to_s == 'String'
      hash_or_message = {:message => hash_or_message}
    end
    
    now = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
    message = hash_or_message[:message].gsub("'", "''")
    
    insert = "INSERT INTO application_logs (application_id, channel_id, ao_message_id, at_message_id, message, severity, created_at, updated_at) VALUES (#{@application_id},#{hash_or_message[:channel_id] || "NULL"},#{hash_or_message[:ao_message_id] || "NULL"},#{hash_or_message[:at_message_id] || "NULL"},'#{message}',#{severity},'#{now}','#{now}')"
    
    ApplicationLog.connection.execute insert
  end
  
  def exception_msg(exception)
    if exception.class == String || exception.class == RuntimeError
      exception
    else
      "#{exception.class} - #{exception}"
    end
  end
  
end
