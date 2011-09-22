class SendXmppMessageJob
  include ReschedulableSendMessageJob

  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform(delegate)
    @msg = AoMessage.find @message_id

    return true if @msg.channel_id != @channel_id
    return true if @msg.state != 'queued'

    @account = Account.find_by_id @account_id
    @channel = @account.channels.find_by_id @channel_id

    begin
      @msg.tries += 1
      @msg.save!

      delegate.send_message(@msg.id, @msg.from.without_protocol, @msg.to.without_protocol, @msg.subject, @msg.body)
      @msg.send_succeed @account, @channel
    rescue MessageException => e
      @msg.send_failed @account, @channel, e
    end
  end

  def to_s
    "<SendXmppMessageJob:#{@message_id}>"
  end
end
