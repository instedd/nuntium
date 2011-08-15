class ManagedProcess < ActiveRecord::Base
  belongs_to :account

  after_create :publish_start_notification
  before_destroy :publish_stop_notification

  # Both are needed, because enabled_changed? is lost in the after_update
  before_update :record_enabled_changed
  after_commit :publish_notification_if_needed, :on => :update

  def publish_start_notification
    publish_notification StartProcessJob
  end

  def publish_stop_notification
    publish_notification StopProcessJob
  end

  def publish_restart_notification
    publish_notification RestartProcessJob
  end

  def record_enabled_changed
    @enabled_changed = enabled_changed?
    true
  end

  def publish_notification_if_needed
    enabled_changed = @enabled_changed
    @enabled_changed = false

    if enabled_changed
      if enabled
        publish_start_notification
      else
        publish_stop_notification
      end
    else
      publish_restart_notification
    end
  end

  def publish_notification(clazz)
    Queues.publish_notification clazz.new(id), 'managed_processes'
  end
end
