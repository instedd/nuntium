module CronDaemonRun
    
  # Gets tasks to run, enqueues a job for each of them and sets next run
  def cron_run
    to_run = CronTask.to_run
    to_run.each { |task| enqueue task }
    rescue => err
      Rails.logger.error "Error running scheduler: #{err}"
    else
      Rails.logger.info "Scheduler executed successfully enqueuing #{to_run.size} task(s)."
    ensure
      CronTask.set_next_run(to_run) unless to_run.nil?
  end

  # Enqueue a descriptor for the specified task
  def enqueue(task)
    Queues.publish_cron_task CronTaskDescriptor.new(task.id)
    Rails.logger.info "Enqueued job for task '#{task.id}'"
  end

end

class CronService < Service

  include CronDaemonRun
  
  def initialize
    super
    Queues.bind_cron_tasks
  end
  
  loop_with_sleep(20) do
    cron_run
  end

end
