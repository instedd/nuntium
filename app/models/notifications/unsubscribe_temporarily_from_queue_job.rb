class UnsubscribeTemporarilyFromQueueJob

  attr_accessor :queue_name

  def initialize(queue_name)
    @queue_name = queue_name
  end

  def perform(worker)
    worker.unsubscribe_temporarily_from_queue @queue_name
  end

  def to_s
    "<UnsubscribeTemporarilyFromQueue:#{queue_name}>"
  end

end
