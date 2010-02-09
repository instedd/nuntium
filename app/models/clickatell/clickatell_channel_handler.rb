class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue create_job(msg)
  end
  
  def handle_now(msg)
    create_job(msg).perform
  end
  
  def create_job(msg)
    SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    check_config_not_blank :api_id
    
    if (@channel.direction & Channel::Incoming) != 0    
      check_config_not_blank :incoming_password
    end
    
    if (@channel.direction & Channel::Outgoing) != 0
      check_config_not_blank :user, :password, :from
    end
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:api_id]
  end
end
