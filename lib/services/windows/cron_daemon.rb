begin
  $log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'cron_daemon.log')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

  require 'win32/daemon'
  include Win32
  
  # Daemon class that will execute the loop
  class CronDaemon < Daemon
    def service_init
      true  
    end
    
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      CronService.new(self).start
    end    
  end
  
  CronDaemon.mainloop
rescue => err
   # If there was an error initializing the rails environment, we cannot use its logger
   File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
   raise
end
