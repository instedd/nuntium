# Initialize Ruby on Rails
begin
  $log_path = File.join(File.dirname(__FILE__), '..', '..', 'log', 'alert_service_daemon.log')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32
  
  class AlertServiceDaemon < Daemon
    # Check alerts every 5 minutes
    SLEEP = 5 * 60
  
    def service_init
      true
    end
  
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      interpreter = AlertInterpreter.new
      sender = AlertSender.new
      while running?
        # Run alert logic
        begin
          Application.all.each { |app| interpreter.interpret_for app }
        rescue Exception => err
          RAILS_DEFAULT_LOGGER.error "Daemon failure when running scripts: #{err} #{err.backtrace}"
        end
        
        # Send pending alerts
        begin
          sender.perform
        rescue Exception => err
          RAILS_DEFAULT_LOGGER.error "Daemon failure when sending alerts: #{err} #{err.backtrace}"
        end
        
        # Wait some minutes
        start = Time.now.to_i
        while running? && (Time.now.to_i - start) < SLEEP
          sleep 1
        end
      end
    rescue Exception => err
      File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
    end
  end
  
  AlertServiceDaemon.mainloop
rescue => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
  raise
end
