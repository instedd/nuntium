class ApplicationLogger
  def initialize(application)
    @application = application
  end
  
  def protocol_not_found_for(ao_msg)
    create(:message => "Protocol not found for #{ao_msg.inspect}")
  end
  
  def no_channel_found_for(protocol, ao_msg)
    create(:message => "No channel found for protocol '#{protocol}' for message #{ao_msg.inspect}")
  end
  
  def more_than_one_channel_found_for(protocol, ao_msg)
    create(:ao_message_id => ao_msg.id, :message => "More than one channel found for protocol '#{protocol}'")
  end
  
  def create(hash)
    hash[:application_id] = @application.id
    ApplicationLog.create(hash)
  end
end