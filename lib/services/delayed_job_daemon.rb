# Initialize Ruby on Rails
begin
  LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = 'development' # ARGV[0] unless ARGV.empty?
  
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "1" }   
  
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "2" }   
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "3" }   
  
  require 'win32/daemon'
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "4" }   
  require 'win32/process'
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "5" }   
  include Win32
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "6" }   
  
  # The code for this daemon was copied from Delayed::Worker
  # and adapted to be run as a Windows Service.
  class DelayedJobDaemon < Daemon
    SLEEP = 5
  
    def service_init
      File.open(LOG_FILE, 'a'){ |fh| fh.puts "8" }
      true
    end
  
    def service_main
      File.open(LOG_FILE, 'a'){ |fh| fh.puts "9" }
      ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
      path = ' "' + File.dirname(File.expand_path($0)).tr('/', '\\')
      path += '\\delayed_job_worker.rb"'
      cmd = ruby + path
      
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
        p.kill
      end
    end
  
    def say(text)
      logger.info text if logger
    end
    
    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
  
  File.open(LOG_FILE, 'a'){ |fh| fh.puts "7" }   
  
  DelayedJobDaemon.mainloop
rescue => err
   File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
   raise
end
