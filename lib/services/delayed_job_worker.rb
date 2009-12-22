def finished
  current_dir = File.dirname(File.expand_path($0)).tr('/', '\\');
  process_file = current_dir + '\\' + Process.pid.to_s
  !File.exists?(process_file)
end

# Initialize Ruby on Rails
begin
  # LOG_FILE = 'C:\\ruby.log'
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  SLEEP = 5
  
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  
  def say(text)
    logger.info text if logger
    # File.open(LOG_FILE, 'a'){ |fh| fh.puts text }   
  end
  
  def logger
    RAILS_DEFAULT_LOGGER
  end
  
  say "*** Starting job worker #{Delayed::Job.worker_name}"

  while !finished
    result = nil

    realtime = Benchmark.realtime do
      result = Delayed::Job.work_off
    end

    count = result.sum

    if count.zero?
      sleep SLEEP
    else
      say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
    end
  end
  
  
rescue => err
  File.open("C:\\ruby.log", 'a'){ |fh| fh.puts 'Daemon failure: ' + err }
  logger.error "Daemon failure: #{err}"
ensure
  # say "*** Stopping job worker #{Delayed::Job.worker_name}"
  Delayed::Job.clear_locks!
end
