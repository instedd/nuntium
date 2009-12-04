# Initialize Ruby on Rails
begin
  LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty? 
  SLEEP = 20
  
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  require 'win32/daemon'
  
  include Win32
  
  # Extracted to a module so we can test it in isolation
  module CronDaemonRun
    
    # Gets tasks to run, enqueues a job for each of them and sets next run
    def cron_run
      to_run = CronTask.to_run
      to_run.each { |task| enqueue task }
      rescue => err
        logger.error "Error running scheduler: #{err}" if defined?(logger) and not logger.nil?
      else
        logger.info "Scheduler executed successfully enqueuing #{to_run.size} task(s)." if defined?(logger) and not logger.nil?
      ensure
        CronTask.set_next_run(to_run) unless to_run.nil?
    end
    
    # Enqueue a descriptor for the specified task
    def enqueue(task)
      Delayed::Job.enqueue CronTaskDescriptor.new(task.id)
      logger.debug "Enqueued job for task '#{task.id}'" if defined?(logger) and not logger.nil?
    end
    
  end
  
  # Daemon class that will execute the loop
  class CronDaemon < Daemon
    
    logger = RAILS_DEFAULT_LOGGER
    
    include CronDaemonRun
    
    def service_main
        while running?
          cron_run
          break if not running?
          sleep SLEEP
        end
    end
    
    def service_stop
      exit!
    end
    
  end
  
  # Start the loop iif this file was invoked directly
  if __FILE__ == $0
    CronDaemon.mainloop
  end

rescue => err
   # If there was an error initializing the rails environment, we cannot use its logger
   File.open(LOG_FILE, 'a'){ |fh| fh.puts "#{Time.now} Daemon failure: #{err}" }
   raise
end