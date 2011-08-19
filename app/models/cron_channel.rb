module CronChannel
  extend ActiveSupport::Concern

  include CronTask::CronTaskOwner

  included do
    after_create :create_tasks, :if => :enabled?
    after_enabled :create_tasks
    after_disabled :destroy_tasks
    before_destroy :destroy_tasks, :if => :enabled?
  end
end
