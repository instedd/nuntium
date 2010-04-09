class ChannelSubscriptionJob
  attr_reader :channel_id
  
  def initialize(channel)
    @channel_id = channel.id
  end
  
  def perform(generic_worker)
  end
end