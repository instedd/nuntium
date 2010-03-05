require 'daemon_controller'

class ManagedProcessesService < Service

  loop_with_sleep(60) do
    @previous_status ||= nil
    @controllers ||= {}
    
    new_status = ManagedProcess.status @previous_status
    new_status.each do |proc, v|
      case v
      when :start
        start_process proc
      when :stop
        stop_process proc
      when :restart
        stop_process proc
        start_process proc
      end
    end
    @previous_status = new_status
  end
  
  def stop
    @controllers.each_key{|proc| stop_process proc}
  end
  
  def start_process(proc)
    logger.info "Starting #{proc.name}"
    controller = create_controller proc
    controller.start
    @controllers[proc] = controller
  rescue Exception => err
    logger.error "Error starting #{proc.name}: #{err} #{err.backtrace}"
  end
  
  def stop_process(proc)
    logger.info "Stopping #{proc.name}"
    controller = @controllers[proc]
    controller.stop
    @controllers.delete proc
  rescue Exception => err
    logger.error "Error stopping #{proc.name}: #{err} #{err.backtrace}"
  end
  
  def create_controller(proc)
    controller = DaemonController.new(
       :identifier    => proc.name,
       :start_command => "#{RAILS_ROOT}/lib/services/unix/#{proc.start_command}",
       :stop_command => "#{RAILS_ROOT}/lib/services/unix/#{proc.stop_command}",
       :ping_command => lambda { true },
       :pid_file      => "#{RAILS_ROOT}/tmp/pids/#{proc.pid_file}",
       :log_file      => "#{RAILS_ROOT}/log/#{proc.log_file}"
    )
    # We want our ping command to be the pid file check:
    # this is the simplest (but hacky) way to do it.
    controller.instance_eval {
      @ping_command = lambda { controller.send('daemon_is_running?') }
    }
    controller
  end
  
end
