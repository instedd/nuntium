# Initialize Ruby on Rails
begin  
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
      File.open('C:\\smppserv.log', 'a'){ |fh| fh.puts 'Daemon failure: ' + error }
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
  File.open('C:\\smppservmain.log', 'a'){ |fh| fh.puts 'Smpp gateway failure: ' + err }
  raise
end
