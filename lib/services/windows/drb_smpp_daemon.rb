begin
  $log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'drb_smpp_daemon.log')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32  
  
  class SmppGatewayDaemon < Daemon       
    SLEEP = 1
    
    def service_init
      true      
    end
    
    def service_main  
      require(File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'services', 'drb_smpp_client'))
      
      channel_id = ARGV[1] unless ARGV.empty?   
      
      startSMPPGateway(channel_id)
      
      while running?
        sleep SLEEP
      end
    rescue => err
      File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
    end
    
    def service_stop      
      stopSMPPGateway
    end
  end
  
  SmppGatewayDaemon.mainloop
rescue => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
  raise
end
