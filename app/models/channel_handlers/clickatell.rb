class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.id, msg.id)
  end
end

class SendClickatellMessageJob < Struct.new(:channel_id, :message_id)
  def perform
  end
end