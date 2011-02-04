class ScheduledJobsService < Service
  loop_with_sleep 60 do
    execute_once
  end

  def execute_once
    Rails.logger.debug "Executing once..."

    jobs = ScheduledJob.all(:conditions => ['run_at <= ?', Time.now.utc])
    jobs.each do |job|
      begin
        job.perform
      rescue Exception => e
        Rails.logger.error "#{e.message}: #{e.backtrace}"
      else
        job.destroy
      end
    end
  end
end
