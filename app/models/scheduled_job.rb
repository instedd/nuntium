class ScheduledJob < ActiveRecord::Base
  before_save :serialize_job

  def self.due_to_run
    where('run_at <= ?', Time.now.utc).all
  end

  def perform
    handler = self.job.deserialize_job
    handler.perform
  end

  private

  def serialize_job
    self.job = self.job.to_yaml
  end
end
