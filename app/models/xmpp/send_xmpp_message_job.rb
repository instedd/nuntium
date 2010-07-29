class SendXmppMessageJob
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
    
    from = msg.from.without_protocol
    to = msg.to.without_protocol
    subject = msg.subject
    body = msg.body
    
    begin
      error_or_nil = delegate.send_message(msg.id, from, to, subject, body)
      msg.send_succeeed account, channel
    rescue => e
      msg.send_failed account, channel, e
    else
      if !error_or_nil.nil?
        msg.send_failed account, channel, error_or_nil
      end
    end
  end
  
  def to_s
    "<SendXmppMessageJob:#{@message_id}>"
  end

end
