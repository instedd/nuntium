RAILS_ROOT=File.join(File.dirname(__FILE__), '..')

%w{3000 3001 3002 3003}.each do |port|
  God.watch do |w|
    w.name = "nuntium-mongrel-#{port}"
    w.interval = 30.seconds
    w.start = "mongrel_rails start -c #{RAILS_ROOT} -p #{port} -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid -d"
    w.stop = "mongrel_rails stop -P #{RAILS_ROOT}/tmp/mongrel.#{port}.pid"
    w.restart = "mongrels_rails restart -P #{RAILS_ROOT}/tmp/mongrel.#{port}.pid"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file = File.join(RAILS_ROOT, "tmp/pids/mongrel.#{port}.pid")
    w.group = 'mongrel'
    
    w.behavior(:clean_pid_file)
    
    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end
  end
end

God.watch do |w|
  w.name = "nuntium-cron"
  w.interval = 5.seconds
  w.start = "ruby #{RAILS_ROOT}/lib/services/unix/cron_daemon_ctrl.rb start"
  w.stop = "ruby #{RAILS_ROOT}/lib/services/unix/cron_daemon_ctrl.rb stop"
  w.pid_file = File.join(RAILS_ROOT, "tmp/pids/cron_daemon.pid")
  w.behavior(:clean_pid_file)
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end

God.watch do |w|
  w.name = "nuntium-throttling"
  w.interval = 5.seconds
  w.start = "ruby #{RAILS_ROOT}/lib/services/unix/throttled_job_daemon_ctl.rb start"
  w.stop = "ruby #{RAILS_ROOT}/lib/services/unix/throttled_job_daemon_ctl.rb stop"
  w.pid_file = File.join(RAILS_ROOT, "tmp/pids/throttled_job_daemon.pid")  
  w.behavior(:clean_pid_file)
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end

God.watch do |w|
  w.name = "nuntium-alert-service"
  w.interval = 5.seconds
  w.start = "ruby #{RAILS_ROOT}/lib/services/unix/alert_service_daemon_ctl.rb start"
  w.stop = "ruby #{RAILS_ROOT}/lib/services/unix/alert_service_daemon_ctl.rb stop"
  w.pid_file = File.join(RAILS_ROOT, "tmp/pids/alert_service_daemon.pid")  
  w.behavior(:clean_pid_file)
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end


4.times do |i|
  God.watch do |w|
    w.name = "nuntium-worker-#{i}"
    w.start = "rake -f #{RAILS_ROOT}/Rakefile jobs:work"
    w.interval = 30.seconds
    w.group = 'worker'

    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
    
  end
end