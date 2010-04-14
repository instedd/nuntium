class CronWorkerService < Service
  
  def start
    MQ.error { |err| Rails.logger.error err }
  
    @session = MQ.new
    Queues.subscribe_cron_tasks @session do |header, task|
      begin
        task.perform
      rescue Exception => ex
        Rails.logger.error "Error executing task #{task}: #{ex}"
      end
    end
  end
  
  def stop(stop_event_machine = true)
    super()
    @session.close
    EM.stop_event_loop if stop_event_machine
  end
end
