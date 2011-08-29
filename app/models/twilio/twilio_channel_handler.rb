class TwilioChannelHandler < GenericChannelHandler
  
  def self.title
    "Twilio"
  end
  
  def check_valid
    check_config_not_blank :account_sid
    check_config_not_blank :auth_token
    check_config_not_blank :from
  end
  
  def info
    @channel.configuration[:account_sid] 
  end
  
end