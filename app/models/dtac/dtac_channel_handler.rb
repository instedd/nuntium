class DtacChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendDtacMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
        
    @channel.errors.add(:sno, "can't be blank") if
        @channel.configuration[:sno].nil? || @channel.configuration[:sno].chomp.empty?
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:sno]
  end
  
end
