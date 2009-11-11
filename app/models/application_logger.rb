class ApplicationLogger
  def initialize(application)
    @application = application
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
  
  def info(hash)
    create(hash, ApplicationLog::Info)
  end
  
  def warning(hash)
    create(hash, ApplicationLog::Warning)
  end
  
  def error(hash)
    create(hash, ApplicationLog::Error)
  end
  
  def create(hash, severity)
    hash[:application_id] = @application.id
    hash[:severity] = severity
    ApplicationLog.create(hash)
  end
end