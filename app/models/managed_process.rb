class ManagedProcess < ActiveRecord::Base

  after_create :publish_start_notification
  before_destroy :publish_stop_notification
  after_update :publish_restart_notification
  
  def publish_start_notification
    publish_notification StartProcessJob
  end
  
  def publish_stop_notification
    publish_notification StopProcessJob
  end
  
  def publish_restart_notification
    publish_notification RestartProcessJob
  end
  
  def publish_notification(clazz)
    Queues.publish_notification clazz.new(id), 'managed_processes'
  end

end
