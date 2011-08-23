require 'daemon_controller'

class ManagedProcessesService < Service

  def start
    @controllers = {}

    ManagedProcess.where(:enabled => true).find_each do |proc|
      start_process proc
    end

    @mq = MQ.new
    Queues.subscribe_notifications('managed_processes', 'managed_processes', @mq) do |header, task|
      task.perform self
    end

    EM.add_periodic_timer(10) do
      @controllers.each do |id, controller|
        if not controller.send('daemon_is_running?')
          logger.warn "Process #{id} is dead. Restarting."
          controller.start
        end
      end
    end
  end

  def stop
    super
    @controllers.each_key{|proc| stop_process proc}
    @mq.close
    EM.stop_event_loop
  end

  def start_process(proc)
    proc = ManagedProcess.find_by_id proc unless proc.kind_of? ManagedProcess
    return unless proc
    return if @controllers.has_key? proc.id

    logger.info "Starting #{proc.name}"
    controller = create_controller proc
    controller.start
  rescue Exception => err
    logger.error "Error starting #{proc.name}: #{err} #{err.backtrace}"
  else
    @controllers[proc.id] = controller
  end

  def stop_process(proc_id)
    return unless @controllers.has_key? proc_id

    logger.info "Stopping #{proc_id}"
    controller = @controllers[proc_id]
    controller.stop
  rescue Exception => err
    logger.error "Error stopping #{proc_id}: #{err} #{err.backtrace}"
  else
    @controllers.delete proc_id
  end

  def restart_process(proc_id)
    logger.info caller
    logger.info "Restarting #{proc_id}"
    stop_process proc_id
    start_process proc_id
  end

  def create_controller(proc)
    controller = DaemonController.new(
       :identifier    => proc.name,
       :start_command => "#{Rails.root}/lib/services/#{proc.start_command}",
       :stop_command => "#{Rails.root}/lib/services/#{proc.stop_command}",
       :ping_command => lambda { true },
       :pid_file      => "#{Rails.root}/tmp/pids/#{proc.pid_file}",
       :log_file      => "#{Rails.root}/log/#{proc.log_file}"
    )
    # We want our ping command to be the pid file check:
    # this is the simplest (but hacky) way to do it.
    controller.instance_eval {
      @ping_command = lambda { controller.send('daemon_is_running?') }
    }
    controller
  end

end
