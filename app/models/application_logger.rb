class ApplicationLogger
  def initialize(application_id)
    @application_id = application_id
  end
  
  def protocol_not_found_for(ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "Protocol not found in 'to' field")
  end
  
  def no_channel_found_for(protocol, ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "No channel found for protocol '#{protocol}'")
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
    logger.error(:channel_id => channel.id, :message => exception.message)
  end
  
  def self.exception_in_channel_and_ao_message(channel, ao_msg, exception)
    logger = ApplicationLogger.new(channel.application_id)
    logger.error(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => exception.message)
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