require 'logger'

begin
  $logger = Logger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'drb_smpp_daemon.log'), 5, 10 * 1024 * 1024)
  $logger.formatter = Logger::Formatter.new
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32  
  
  class SmppGatewayDaemon < Daemon       
    SLEEP = 5
    
    def service_init
      true      
    end
    
    def service_main  
      require(File.join(File.dirname(__FILE__), 'drb_smpp_client'))
      
      channel_id = ARGV[1] unless ARGV.empty?   
      
      startSMPPGateway(channel_id)
      
      while running?
        sleep SLEEP
      end       
    rescue => error
      $logger.error "Daemon failure: #{error}"
    end
    
    def service_stop      
      stopSMPPGateway
    end
    
    def say(text)
      $logger.info text if $logger
    end
  end
  
  SmppGatewayDaemon.mainloop
rescue => err
  $logger.error "Daemon failure: #{err}"
  raise
end
