class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:api_ID, "can't be blank") if
        @channel.configuration[:api_id].blank?
    
    if (@channel.direction & Channel::Incoming) != 0    
      @channel.errors.add(:incoming_password, "can't be blank") if
          @channel.configuration[:incoming_password].blank?
    end
    
    if (@channel.direction & Channel::Outgoing) != 0
      @channel.errors.add(:user, "can't be blank") if
          @channel.configuration[:user].blank?
          
      @channel.errors.add(:password, "can't be blank") if
          @channel.configuration[:password].blank?
          
      @channel.errors.add(:from, "can't be blank") if
          @channel.configuration[:from].blank?
    end
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:api_id]
  end
end
