module CronDaemonRun
    
  # Gets tasks to run, enqueues a job for each of them and sets next run
  def cron_run
    to_run = CronTask.to_run
    to_run.each { |task| enqueue task }
    rescue => err
      RAILS_DEFAULT_LOGGER.error "Error running scheduler: #{err}"
    else
      RAILS_DEFAULT_LOGGER.debug "Scheduler executed successfully enqueuing #{to_run.size} task(s)."
    ensure
      CronTask.set_next_run(to_run) unless to_run.nil?
  end

  # Enqueue a descriptor for the specified task
  def enqueue(task)
    Delayed::Job.enqueue CronTaskDescriptor.new(task.id)
    RAILS_DEFAULT_LOGGER.debug "Enqueued job for task '#{task.id}'"
  end

end

class CronService < Service

  include CronDaemonRun

  def start
    while running?
      cron_run
      break if not running?
      
      daydream 20
    end
  end

end
