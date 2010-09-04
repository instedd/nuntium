class WorkerQueue < ActiveRecord::Base

  after_commit_on_create :publish_subscribe_notification
  before_commit_on_destroy  :publish_unsubscribe_notification
  
  private
  
  def publish_subscribe_notification
    Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
  end
  
  def publish_unsubscribe_notification
    Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
  end

end
