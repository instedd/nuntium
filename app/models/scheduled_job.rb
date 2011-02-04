class ScheduledJob < ActiveRecord::Base
  before_save :serialize_job

  def perform
    handler = self.job.deserialize_job
    handler.perform
  end

  private

  def serialize_job
    self.job = self.job.to_yaml
  end
end
