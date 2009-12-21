# Initialize Ruby on Rails
begin
  LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32
  
  # The code for this daemon was copied from Delayed::Worker
  # and adapted to be run as a Windows Service.
  class DelayedJobDaemon < Daemon
    SLEEP = 5
  
    def service_init
      File.open(LOG_FILE, 'a'){ |fh| fh.puts "8" }
      true
    end
  
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
    
      File.open(LOG_FILE, 'a'){ |fh| fh.puts "9" }
      ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
      path = ' "' + File.dirname(File.expand_path($0)).tr('/', '\\')
      path += '\\delayed_job_worker.rb"'
      cmd = ruby + path + ' ' + ENV["RAILS_ENV"]
      
      File.open(LOG_FILE, 'a'){ |fh| fh.puts "Command: #{cmd}" }   
      
      @processes = []
      (1..8).each do
        pi = Process.create(:app_name => cmd)
        File.open(LOG_FILE, 'a'){ |fh| fh.puts pi.to_s }   
        @processes.push pi
      end
      
      while running?
        sleep SLEEP
      end
    rescue => err
      # File.open("C:\\temp_ruby.log", 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
      File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + err }   
    end
    
    def service_stop
      @processes.each do |p|
        Process.kill(9, p.process_id)
      end
    end
  
    def say(text)
      logger.info text if logger
    end
    
    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
  
  DelayedJobDaemon.mainloop
rescue => err
   File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
   raise
end
