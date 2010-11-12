# Generic channel handler that enqueues jobs to rabbit.
# Subclasses must define job_class
class GenericChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def create_job(msg)
    job_class.new(@channel.account_id, @channel.id, msg.id)
  end

  def on_enable
    Queues.bind_ao @channel
    WorkerQueue.create!(:queue_name => Queues.ao_queue_name_for(@channel), :working_group => 'fast', :ack => true, :durable => true)
  end

  def on_disable
    wq = WorkerQueue.find_by_queue_name Queues.ao_queue_name_for(@channel)
    wq.destroy if wq
  end

  def on_pause
    wq = WorkerQueue.find_by_queue_name Queues.ao_queue_name_for(@channel)
    return unless wq

    wq.enabled = false
    wq.save!
  end

  def on_resume
    wq = WorkerQueue.find_by_queue_name Queues.ao_queue_name_for(@channel)
    return unless wq

    wq.enabled = true
    wq.save!
  end
end
