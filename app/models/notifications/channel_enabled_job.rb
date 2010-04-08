class ChannelEnabledJob
  attr_reader :channel_id
  
  def initialize(channel)
    @channel_id = channel.id
  end
end