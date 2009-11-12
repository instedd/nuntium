class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
        
    @channel.errors.add(:api_ID, "can't be blank") if
        @channel.configuration[:api_id].nil? || @channel.configuration[:api_id].chomp.empty?
        
    @channel.errors.add(:incoming_password, "can't be blank") if
        @channel.configuration[:incoming_password].nil? || @channel.configuration[:incoming_password].chomp.empty?
  end
end
