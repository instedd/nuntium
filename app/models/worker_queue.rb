class WorkerQueue < ActiveRecord::Base

  after_commit_on_create :publish_subscribe_notification
  before_commit_on_destroy  :publish_unsubscribe_notification

  # Both are needed, because enabled_changed? is lost in the after_update
  before_update :record_enabled_changed
  after_commit_on_update :publish_notification_if_enabled_changed

  after_commit_on_destroy :delete_queue

  def self.for_channel(channel)
    find_by_queue_name Queues.ao_queue_name_for(channel)
  end

  def self.for_application(app)
    find_by_queue_name Queues.application_queue_name_for(app)
  end

  def self.find_each_enabled_for_working_group(working_group, &block)
    find_each(:conditions => ['working_group = ? AND enabled = ?', working_group, true], &block)
  end

  def subscribe(mq = Queues::DefaultMQ, &block)
    Queues.subscribe queue_name, ack, durable, mq, &block
  end

  private

  def publish_subscribe_notification
    Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
  end

  def publish_unsubscribe_notification
    Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
  end

  def record_enabled_changed
    @enabled_changed = enabled_changed?
    true
  end

  def publish_notification_if_enabled_changed
    enabled_changed = @enabled_changed
    @enabled_changed = false

    return unless enabled_changed

    if enabled
      Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
    else
      Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
    end
  end

  def delete_queue
    Queues.delete queue_name, durable
  end

end
