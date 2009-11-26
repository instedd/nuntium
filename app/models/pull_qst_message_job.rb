class PullQstMessageJob
  
  def initialize(app_id)
    @application_id = app_id
  end
  
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Application.find_all_by_interface('qst').each do |app|
      job = PullQstMessageJob.new(app_id)
      Delayed::Job.enqueue job
    end
  end
  
end