class UnsubscribeFromQueueJob

  attr_accessor :queue_name

  def initialize(queue_name)
    @queue_name = queue_name
  end
  
  def perform(worker)
    worker.unsubscribe_from_queue @queue_name
  end

end
