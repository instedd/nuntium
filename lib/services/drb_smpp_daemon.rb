# Initialize Ruby on Rails
begin
  LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require(File.join(File.dirname(__FILE__), 'drb_smpp_client'))  
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32  
  
  class SmppGatewayDaemon < Daemon       
    SLEEP = 5
    NUMBER_OF_PROCESSES = 2
    
    @smppGateway = nil
    
    def service_init
      true      
    end
  
    def service_main  
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      channel_id = ARGV[1] unless ARGV.empty?   
      
      startSMPPGateway(channel_id)
      
      while running?
        sleep SLEEP
      end       
    end
    
    def service_stop      
      stopSMPPGateway
    end
  
    def say(text)
      logger.info text if logger
    end
    
    def logger      
      RAILS_DEFAULT_LOGGER
    end
  end
  
  SmppGatewayDaemon.mainloop
rescue => err
   # File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Smpp gateway failure: ' + err }
   raise
end
