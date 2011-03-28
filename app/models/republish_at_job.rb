class RepublishAtJob
  attr_accessor :application_id
  attr_accessor :message_id
  attr_accessor :job

  def initialize(application_id, message_id, job)
    @application_id = application_id
    @message_id = message_id
    @job = job
  end

  def perform
    msg = ATMessage.find @message_id
    msg.state = 'queued'
    msg.save!

    app = Application.find @application_id
    Queues.publish_application(app, @job)
  end
end
