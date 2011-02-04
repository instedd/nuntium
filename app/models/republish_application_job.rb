class RepublishApplicationJob
  attr_accessor :application_id
  attr_accessor :job

  def initialize(application_id, job)
    @application_id = application_id
    @job = job
  end

  def perform
    app = Application.find @application_id
    Queues.publish_application(app, @job)
  end
end
