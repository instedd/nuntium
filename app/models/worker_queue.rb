class WorkerQueue < ActiveRecord::Base

  after_create :publish_subscribe_notification
  before_destroy  :publish_unsubscribe_notification
  
  private
  
  def publish_subscribe_notification
    # Since this callback is executed inside a transaction, delay the
    # notification one second to allow the transaction to be committed.
    # Otherwise the workers wont see the new record.
    EM.add_timer(1) do
      Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
    end
  end
  
  def publish_unsubscribe_notification
    Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
  end

end
