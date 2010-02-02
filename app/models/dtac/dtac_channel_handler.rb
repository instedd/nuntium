class DtacChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendDtacMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    check_config_not_blank :user, :password, :sno
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:sno]
  end
  
end
