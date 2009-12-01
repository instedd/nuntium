# Initialize Ruby on Rails
begin
  LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty? 
  SLEEP = 20
  
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  require 'win32/daemon'
  
  include Win32
  
  # To a module so we can test it in isolation
  module CronDaemonRun
    def cron_run
      logger.info "Running" if defined?(logger)
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