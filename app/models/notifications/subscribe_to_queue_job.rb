class SubscribeToQueueJob

  attr_accessor :queue_name

  def initialize(queue_name)
    @queue_name = queue_name
  end
  
  def perform
  end

end
