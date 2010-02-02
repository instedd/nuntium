class DtacChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendDtacMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].blank?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].blank?
        
    @channel.errors.add(:sno, "can't be blank") if
        @channel.configuration[:sno].blank?
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:sno]
  end
  
end
