# Initialize Ruby on Rails
begin
  ENV["RAILS_ENV"] = "production"
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  require 'win32/daemon'
  include Win32
  
  # The code for this daemon was copied from Delayed::Worker
  # and adapted to be run as a Windows Service.
  class DelayedJobDaemon < Daemon
    SLEEP = 5
  
    cattr_accessor :logger
    self.logger = if defined?(Merb::Logger)
      Merb.logger
    elsif defined?(RAILS_DEFAULT_LOGGER)
      RAILS_DEFAULT_LOGGER
    end
  
    def service_main
      say "*** Starting job worker #{Delayed::Job.worker_name}"

      while running?
        result = nil

        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end

        count = result.sum

        break if !running?

        if count.zero?
          sleep SLEEP
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        break if !running?
      end
    rescue => err
      # File.open("C:\\temp_ruby.log", 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
      File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + err }   
    ensure
      Delayed::Job.clear_locks!
    end
  
    def service_stop
      exit!
    end
    
    def say(text)
      logger.info text if logger
    end
  end
  
  DelayedJobDaemon.mainloop
rescue => err
   # File.open("C:\\temp_ruby.log", 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
   File.open(LOG_FILE, 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
   raise
end
