# Generic channel handler that enqueues jobs to rabbit.
# Subclasses must define job_class
class GenericChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def create_job(msg)
    job_class.new(@channel.account_id, @channel.id, msg.id)
  end

  def on_create
    Queues.bind_ao @channel
    WorkerQueue.create!(:queue_name => Queues.ao_queue_name_for(@channel), :working_group => 'fast', :ack => true, :durable => true)
  end

  def on_enable
    wq = WorkerQueue.for_channel @channel
    return unless wq

    wq.enabled = true
    wq.save!
  end

  def on_disable
    wq = WorkerQueue.for_channel @channel
    return unless wq

    wq.enabled = false
    wq.save!
  end

  def on_pause
    on_disable
  end

  def on_resume
    on_enable
  end

  def on_destroy
    wq = WorkerQueue.for_channel @channel
    wq.destroy if wq
  end
end
