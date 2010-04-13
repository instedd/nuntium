class CronWorkerService < Service
  
  def start
    
    @session = MQ.new
    Queues.subscribe_cron_tasks @session do |header, task|
      task.perform
    end
        
  end
  
  def stop
  end
end