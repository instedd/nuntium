def finished
  current_dir = File.dirname(File.expand_path($0)).tr('/', '\\');
  process_file = current_dir + '\\' + Process.pid.to_s
  !File.exists?(process_file)
end

begin
  $log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'delayed_job_worker.log')
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
  SLEEP = 5
  
  require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))
  
  RAILS_DEFAULT_LOGGER.info "*** Starting job worker #{Delayed::Job.worker_name}"

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
        RAILS_DEFAULT_LOGGER.info "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
      end
    rescue Exception => err
      RAILS_DEFAULT_LOGGER.error "Daemon failure: #{err} #{err.backtrace}"
    end
  end
rescue => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}" }
ensure
  Delayed::Job.clear_locks!
end
