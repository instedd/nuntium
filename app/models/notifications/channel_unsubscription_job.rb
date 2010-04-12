class ChannelUnsubscriptionJob
  attr_reader :channel_id
  
  def initialize(channel_id)
    @channel_id = channel_id
  end
  
  def perform(generic_worker)
    generic_worker.unsubscribe_from_channel @channel_id
  end
  
  def to_s
    "Unsubscribe from #{@channel_id}"
  end
  
  def inspect
    to_s
  end
end
