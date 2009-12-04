# Descriptor of a cron task to be executed by delayed job
class CronTaskDescriptor
  attr_accessor :task_id
  cattr_accessor :logger
  
  self.logger = RAILS_DEFAULT_LOGGER

  def initialize(task_id)
    @task_id = task_id
  end
  
  def perform
    task = CronTask.find_by_id @task_id
    if not task.nil? then task.perform else logger.warn "Cannot execute descriptor for missing task with id '#{@task_id}'" end
  end
end
