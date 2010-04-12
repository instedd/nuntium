class ChannelSubscriptionJob
  attr_reader :channel_id
  
  def initialize(channel_id)
    @channel_id = channel_id
  end
  
  def perform(generic_worker)
    generic_worker.subscribe_to_channel @channel_id
  end
end
