class ScheduledJobsService < Service
  loop_with_sleep 60 do
    execute_once
  end

  def execute_once
    Rails.logger.debug "Executing once..."

    ScheduledJob.due_to_run.each { |job| perform_and_destroy job }
  end

  def perform_and_destroy(job)
    job.perform
  rescue Exception => e
    Rails.logger.error "#{e.message}: #{e.backtrace}"
  else
    job.destroy
  end
end
