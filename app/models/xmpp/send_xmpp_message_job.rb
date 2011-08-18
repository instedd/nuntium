class SendXmppMessageJob
  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform(delegate)
    account = Account.find_by_id @account_id
    channel = account.channels.find_by_id @channel_id
    msg = AOMessage.find @message_id

    begin
      msg.tries += 1
      delegate.send_message(msg.id, msg.from.without_protocol, msg.to.without_protocol, msg.subject, msg.body)
      msg.send_succeeed account, channel
    rescue => e
      msg.send_failed account, channel, e
    end
  end

  def to_s
    "<SendXmppMessageJob:#{@message_id}>"
  end

end
