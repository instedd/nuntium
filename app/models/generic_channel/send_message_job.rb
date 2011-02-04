# Generic job to send a message via a channel.
# Subclasses must implement managed_perform.
class SendMessageJob

  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    begin
      @msg = AOMessage.find @message_id

      return true if @msg.channel_id != @channel_id
      return true if @msg.state != 'queued'

      @account = Account.find_by_id @account_id
      @channel = @account.find_channel @channel_id
      @config = @channel.configuration

      @msg.tries += 1
      @msg.save!

      managed_perform
    rescue MessageException => ex
      @msg.send_failed @account, @channel, ex.inner
    rescue PermanentException => ex
      alert_msg = "Permanent exception when trying to send message with id #{@msg.id}: #{ex}"
      @channel.alert alert_msg
      raise alert_msg
    end
  end

  # Should send the message.
  # If there's a failure, one of these exceptions
  # should be thrown:
  #  - MessageException: intrinsic to the message
  #  - PermanentException: like "the password is wrong"
  #  - Exception: like "we don't have an internet connection" (temporary or unknown exception)
  # If there's no error, @msg.send_succeeed must be invoked.
  def managed_perform
    raise PermanentException.new(Exception.new("managed_perform method is not implemented for #{self.class.name}"))
  end

  def reschedule(ex)
    @msg.state = 'delayed'
    @msg.save!

    @account.logger.warning :channel_id => @channel.id, :ao_message_id => @message_id, :message => ex.message

    new_job = self.class.new @account_id, @channel_id, @message_id
    ScheduledJob.create! :job => RepublishAoMessageJob.new(@message_id, new_job), :run_at => 1.minute.from_now
  end

  def to_s
    "<#{self.class}:#{@message_id}>"
  end

end
