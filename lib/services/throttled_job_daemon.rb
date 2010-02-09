require 'logger'

# Initialize Ruby on Rails
begin
  logger = Logger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'throttled_job_daemon.log'))
  logger.formatter = Logger::Formatter.new
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32
  
  class ThrottledJobDaemon < Daemon
    SLEEP = 60
  
    def service_init
      true
    end
  
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      worker = ThrottledWorker.new
      while running?
        begin
          worker.perform
        rescue Exception => err
          logger.error "Daemon failure: #{err}"   
        ensure
          sleep SLEEP
        end
      end
    rescue Exception => err
      logger.error "Daemon failure: #{err}"   
    end
  
    def say(text)
      logger.info text if logger
    end
  end
  
  ThrottledJobDaemon.mainloop
rescue => err
  logger.error "Daemon failure: #{err}"
  raise
end
