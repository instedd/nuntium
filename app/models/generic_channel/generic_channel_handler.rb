# Generic channel handler that enqueues jobs to rabbit.
# Subclasses must define job_class
class GenericChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end
  
  def handle_now(msg)
    create_job(msg).perform
  end
  
  def create_job(msg)
    job_class.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def on_enable
    Queues.bind_ao @channel
    Queues.publish_notification ChannelEnabledJob.new(@channel)
  end
  
  def on_disable
    Queues.publish_notification ChannelDisabledJob.new(@channel)
  end
  
  def job_class
    raise "The job_class method must be defined for #{self.class}"
  end
end
