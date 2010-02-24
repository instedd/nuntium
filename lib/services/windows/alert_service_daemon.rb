# Initialize Ruby on Rails
begin
  $log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'alert_service_daemon.log')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32
  
  class AlertServiceDaemon < Daemon
    def service_init
      true
    end
  
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      AlertService.new(self).start
    rescue Exception => err
      File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
    end
  end
  
  AlertServiceDaemon.mainloop
rescue => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
  raise
end
