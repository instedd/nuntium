require 'logger'

begin
  $logger = Logger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'delayed_job_daemon.log'))
  $logger.formatter = Logger::Formatter.new
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  
  require 'win32/daemon'
  require 'win32/process'
  include Win32
  
  # The code for this daemon was copied from Delayed::Worker
  # and adapted to be run as a Windows Service.
  class DelayedJobDaemon < Daemon
    SLEEP = 1
    NUMBER_OF_PROCESSES = 2
  
    def service_init
      true
    end
  
    def service_main
      require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
      require(File.join(RAILS_ROOT, 'config', 'environment'))
      
      current_dir = File.dirname(File.expand_path($0)).tr('/', '\\');
    
      ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
      path = ' "' + current_dir
      path += '\\delayed_job_worker.rb"'
      cmd = ruby + path + ' ' + ENV["RAILS_ENV"]
      
      # Create processes and pids file for each of them
      @processes = []
      (1..NUMBER_OF_PROCESSES).each do
        pi = Process.create(:app_name => cmd)
        File.open(current_dir + "\\" + pi.process_id.to_s, 'a') { |fh| fh.puts "Working" }
        @processes.push pi
      end
      
      while running?
        sleep SLEEP
      end
    rescue => err
      $logger.error "Daemon failure: #{err} #{err.backtrace}"
    end
    
    def service_stop
      current_dir = File.dirname(File.expand_path($0)).tr('/', '\\');
    
      # Delete the pids file so that the processes can exit cleanly
      @processes.each do |pi|
        File.delete(current_dir + "\\" + pi.process_id.to_s)
      end
    end
  
    def say(text)
      $logger.info text if $logger
    end
  end
  
  DelayedJobDaemon.mainloop
rescue => err
   $logger.error "Daemon failure: #{err} #{err.backtrace}"
   raise
end
