class SendSmppMessageJob
  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end
  
  def perform(delegate)
    account = Account.find_by_id @account_id
    channel = account.find_channel @channel_id
    msg = AOMessage.find @message_id
    
    return false if msg.state != 'queued' or msg.channel_id != @channel_id
    
    from = msg.from.without_protocol
    to = msg.to.without_protocol
    sms = msg.subject_and_body
    
    begin
      return delegate.send_message(msg.id, from, to, sms)
    rescue => e
      msg.send_failed account, channel, e
      return false
    end
  end
  
  def to_s
    "<SendSmppMessageJob:#{@message_id}>"
  end
  
end
