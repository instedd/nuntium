def finished
  current_dir = File.dirname(File.expand_path($0)).tr('/', '\\');
  process_file = current_dir + '\\' + Process.pid.to_s
  !File.exists?(process_file)
end

begin
  require(File.join(File.dirname(__FILE__), '..', '..', 'app', 'models', 'nuntium_logger'))
  $logger = NuntiumLogger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', 'delayed_job_worker.log'), 'delayed_job_worker')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  SLEEP = 5
  
  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  
  def say(text)
    $logger.info text if $logger
  end
  
  say "*** Starting job worker #{Delayed::Job.worker_name}"

  while !finished
    begin
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
    rescue Exception => err
      $logger.error "Daemon failure: #{err} #{err.backtrace}"
    end
  end
rescue => err
  $logger.error "Daemon failure: #{err} #{err.backtrace}"
ensure
  Delayed::Job.clear_locks!
end
