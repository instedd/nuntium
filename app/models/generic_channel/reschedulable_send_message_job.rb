module ReschedulableSendMessageJob
  def reschedule(ex)
    @msg.state = 'delayed'
    @msg.save!

    @account.logger.warning :channel_id => @channel.id, :ao_message_id => @message_id, :message => ex.message

    new_job = self.class.new @account_id, @channel_id, @message_id
    ScheduledJob.create! :job => RepublishAoMessageJob.new(@message_id, new_job), :run_at => @msg.tries.as_exponential_backoff.minutes.from_now
  end
end
