class SendSmppMessageJob
  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform(delegate)
    account = Account.find_by_id @account_id
    channel = account.channels.find_by_id @channel_id
    msg = AoMessage.find @message_id

    return false if msg.state != 'queued' or msg.channel_id != @channel_id

    from = msg.from.protocol == 'sms' ? msg.from.without_protocol : channel.address.without_protocol
    to = msg.to.without_protocol
    sms = msg.subject_and_body

    error = delegate.send_message(msg.id, from, to, sms)
    if error
      msg.send_failed account, channel, error
      false
    else
      true
    end
  end

  def to_s
    "<SendSmppMessageJob:#{@message_id}>"
  end
end
