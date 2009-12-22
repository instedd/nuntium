class ApplicationLogger
  def initialize(application_id)
    @application_id = application_id
  end
  
  def protocol_not_found_for_ao_message(ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "Protocol not found in 'to' field")
  end

  def no_channel_found_for_ao_message(protocol, ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "No channel found for protocol '#{protocol}'")
  end
  
  def at_message_delivery_succeeded(msg, interface)
    info(:at_message_id => msg.id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} succeeded")
  end
  
  def at_message_delivery_exceeded_tries(msg, interface)
    info(:at_message_id => msg.id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} exceeded maximum number of tries")
  end
  
  def ao_message_delivery_succeeded(msg, interface)
    info(:ao_message_id => msg.id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} succeeded")
  end
  
  def ao_message_delivery_exceeded_tries(msg, interface)
    info(:ao_message_id => msg.id, :message => 'Try #' + "#{msg.tries} for delivering message through interface #{interface} exceeded maximum number of tries")
  end
  
  def ao_message_received(msg, interface)
    info(:ao_message_id => msg.id, :message => "Message received via interface #{interface}")
  end
  
  def ao_message_handled_by_channel(msg, channel)
    info(:ao_message_id => msg.id, :message => "Message handled by #{channel.kind} channel '#{channel.name}'")
  end
  
  def at_message_received_via_channel(msg, channel)
    info(:at_message_id => msg.id, :message => "Message received via #{channel.kind} channel '#{channel.name}'")
  end
  
  def at_message_received_via(msg, via)
    info(:at_message_id => msg.id, :message => "Message received via #{via}")
  end
  
  def error_routing_msg(ao_msg, e)
    error(:message => "Error routing message '#{e.to_s}'", :ao_message_id => ao_msg.id)
  end

  def error_obtaining_last_id(message)
    error(:message => "Error obtaining last id from server in QST operation: '#{message}'")
  end

  def error_initializing_http(exception)
    error(:message => "Error initializing http connection in QST operation: '#{exception.message}'")
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
    warning(:ao_message_id => ao_msg.id, :message => "More than one channel found for protocol '#{protocol}'")
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
    logger.error(:channel_id => channel.id, :message => exception.to_s)
  end
  
  def self.exception_in_channel_and_ao_message(channel, ao_msg, exception)
    logger = ApplicationLogger.new(channel.application_id)
    logger.error(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => 'Try #' + "#{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' failed:" + exception.to_s)
  end
  
  def self.message_channeled(ao_msg, channel)
    logger = ApplicationLogger.new(channel.application_id)
    logger.info(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => 'Try #' + "#{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' succeeded")
  end
  
  def create(hash_or_message, severity)
    if hash_or_message.class.to_s == 'String'
      hash_or_message = {:message => hash_or_message}
    end
    hash_or_message[:application_id] = @application_id
    hash_or_message[:severity] = severity
    ApplicationLog.create(hash_or_message)
  end
end