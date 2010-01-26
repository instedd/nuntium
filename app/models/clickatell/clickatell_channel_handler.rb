class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:api_ID, "can't be blank") if
        @channel.configuration[:api_id].nil? || @channel.configuration[:api_id].chomp.empty?
    
    if (@channel.direction & Channel::Incoming) != 0    
      @channel.errors.add(:incoming_password, "can't be blank") if
          @channel.configuration[:incoming_password].nil? || @channel.configuration[:incoming_password].chomp.empty?
    end
    
    if (@channel.direction & Channel::Outgoing) != 0
      @channel.errors.add(:user, "can't be blank") if
          @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
          
      @channel.errors.add(:password, "can't be blank") if
          @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
          
      @channel.errors.add(:from, "can't be blank") if
          @channel.configuration[:from].nil? || @channel.configuration[:from].chomp.empty?
    end
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:api_id]
  end
end
