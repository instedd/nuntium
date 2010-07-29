class DtacChannelHandler < GenericChannelHandler

  def job_class
    SendDtacMessageJob
  end
  
  def check_valid
    check_config_not_blank :user, :password
  end
  
  def info
    @channel.configuration[:user]
  end
  
end
