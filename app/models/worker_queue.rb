class WorkerQueue < ActiveRecord::Base

  after_create :publish_subscribe_notification
  before_destroy  :publish_unsubscribe_notification
  
  private
  
  def publish_subscribe_notification
    Queues.publish_notification_2 SubscribeToQueueJob.new(queue_name), working_group
  end
  
  def publish_unsubscribe_notification
    Queues.publish_notification_2 UnsubscribeFromQueueJob.new(queue_name), working_group
  end

end
