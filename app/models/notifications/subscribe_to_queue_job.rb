class SubscribeToQueueJob

  attr_accessor :queue_name

  def initialize(queue_name)
    @queue_name = queue_name
  end
  
  def perform(worker)
    worker.subscribe_to_queue @queue_name
  end
  
  def to_s
    "<SubscribeToQueue:#{queue_name}>"
  end

end
