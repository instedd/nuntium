class WorkerQueue < ActiveRecord::Base

  @@publish_notification_delay = 1

  after_create :publish_subscribe_notification
  before_destroy  :publish_unsubscribe_notification
  
  def self.publish_notification_delay=(value)
    @@publish_notification_delay = value
  end
  
  def self.publish_notification_delay
    @@publish_notification_delay
  end
  
  private
  
  def publish_subscribe_notification
    # Since this callback is executed inside a transaction, delay the
    # notification one second to allow the transaction to be committed.
    # Otherwise the workers wont see the new record.
    publish = proc { Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group } 
    if WorkerQueue.publish_notification_delay > 0
      EM.add_timer(WorkerQueue.publish_notification_delay) do
        publish.call
      end
    else
      publish.call
    end
  end
  
  def publish_unsubscribe_notification
    Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
  end

end
