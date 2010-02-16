# Initialize Ruby on Rails
begin
  require(File.join(File.dirname(__FILE__), '..', '..', 'app', 'models', 'nuntium_logger'))
  $logger = NuntiumLogger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'throttled_job_daemon.log'), 'throttled_job_daemon')
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
          $logger.error "Daemon failure: #{err} #{err.backtrace}"   
        ensure
          start = Time.now.to_i
          while running? && (Time.now.to_i - start) < SLEEP
            sleep 1
          end
        end
      end
    rescue Exception => err
      $logger.error "Daemon failure: #{err} #{err.backtrace}"   
    end
  
    def say(text)
      $logger.info text if $logger
    end
  end
  
  ThrottledJobDaemon.mainloop
rescue => err
  $logger.error "Daemon failure: #{err} #{err.backtrace}"
  raise
end
