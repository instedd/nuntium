class QstClientChannelHandler < ChannelHandler
  def handle(msg)
  end
  
  def check_valid
    @channel.errors.add(:url, "can't be blank") if
        @channel.configuration[:url].nil? || @channel.configuration[:url].chomp.empty?
        
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
  end
end