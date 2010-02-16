begin
  require(File.join(File.dirname(__FILE__), '..', '..', 'app', 'models', 'nuntium_logger'))
  $logger = NuntiumLogger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'cron_daemon.log'), 'cron_daemon')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty? 
  SLEEP = 20

  require 'win32/daemon'
  include Win32
  
  # Extracted to a module so we can test it in isolation
  module CronDaemonRun
    
    # Gets tasks to run, enqueues a job for each of them and sets next run
    def cron_run
      to_run = CronTask.to_run
      to_run.each { |task| enqueue task }
      rescue => err
        $logger.error "Error running scheduler: #{err}" if defined?($logger) and not $logger.nil?
      else
        $logger.debug "Scheduler executed successfully enqueuing #{to_run.size} task(s)." if defined?($logger) and not $logger.nil?
      ensure
        CronTask.set_next_run(to_run) unless to_run.nil?
    end
    
    # Enqueue a descriptor for the specified task
    def enqueue(task)
      Delayed::Job.enqueue CronTaskDescriptor.new(task.id)
      $logger.debug "Enqueued job for task '#{task.id}'" if defined?($logger) and not $logger.nil?
    end
    
  end
  
  # Daemon class that will execute the loop
  class CronDaemon < Daemon
    
    include CronDaemonRun
    
    def service_init
      true  
    end
    
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      while running?
        cron_run
        break if not running?
        
        start = Time.now.to_i
        while running? && (Time.now.to_i - start) < SLEEP
          sleep 1
        end
      end
    end
    
  end
  
  # Start the loop iif this file was invoked directly
  if __FILE__ == $0
    CronDaemon.mainloop
  end

rescue => err
   # If there was an error initializing the rails environment, we cannot use its logger
   $logger.error "Daemon failure: #{err} #{err.backtrace}"
   raise
end
