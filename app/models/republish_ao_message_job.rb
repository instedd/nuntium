class RepublishAoMessageJob
  attr_accessor :message_id
  attr_accessor :job

  def initialize(message_id, job)
    @message_id = message_id
    @job = job
  end

  def perform
    msg = AOMessage.find @message_id
    return if msg.state != 'delayed'

    msg.state = 'queued'
    msg.save!

    Queues.publish_ao(msg, @job)
  end
end
