class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
end
