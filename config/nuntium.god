RAILS_ROOT=File.join(File.dirname(__FILE__), '..')

# == Helper functions ==

def manage_gracefuly(w)
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

def service(name, *args)
  God.watch do |w|
    name_suffix = args.length == 0 ? "" : args.join('-')
    w.name = "nuntium-#{name.gsub('_', '-')}#{name_suffix}"
    w.interval = 5.seconds
    service_args = "production" + (args.length == 0 ? "" : " #{args.join(' ')}")
    w.start = "ruby #{RAILS_ROOT}/lib/services/#{name}_daemon_ctl.rb start -- #{service_args}"
    w.stop = "ruby #{RAILS_ROOT}/lib/services/#{name}_daemon_ctl.rb stop -- #{service_args}"
    pid_file_suffix = args.length == 0 ? "" : ".#{args.join('.')}"
    w.pid_file = File.join(RAILS_ROOT, "tmp/pids/#{name}_daemon#{pid_file_suffix}.pid")
    #w.behavior(:clean_pid_file)
    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end

# == Services start here ==

%w{3000 3001 3002 3003}.each do |port|
  God.watch do |w|
    w.name = "nuntium-mongrel-#{port}"
    w.interval = 30.seconds
    w.start = "mongrel_rails start -c #{RAILS_ROOT} -p #{port} -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid -d -e production"
    w.stop = "mongrel_rails stop -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid"
    w.restart = "mongrels_rails restart -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid"
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
    
    yield w if block_given?
  end
end

service 'alert_service'
service 'cron'

['slow', 'fast'].each do |working_group|
  4.times do |i|
    service 'generic_worker', working_group, i do |w|
      manage_gracefuly w
    end
  end
end

service 'managed_processes'
