class ApplicationLogger
  def initialize(application)
    @application = application
  end
  
  def protocol_not_found_for(ao_msg)
    create(:ao_message_id => ao_msg.id, :message => "Protocol not found in 'to' field")
  end
  
  def no_channel_found_for(protocol, ao_msg)
    create(:ao_message_id => ao_msg.id, :message => "No channel found for protocol '#{protocol}'")
  end
  
  def more_than_one_channel_found_for(protocol, ao_msg)
    create(:ao_message_id => ao_msg.id, :message => "More than one channel found for protocol '#{protocol}'")
  end
  
  def create(hash)
    hash[:application_id] = @application.id
    ApplicationLog.create(hash)
  end
end