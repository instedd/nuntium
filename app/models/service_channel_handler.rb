# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
class ServiceChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def on_enable
    ManagedProcess.create!(
      :account_id => @channel.account.id,
      :name => managed_process_name,
      :start_command => "service_daemon_ctl.rb start -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :stop_command => "service_daemon_ctl.rb stop -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      # The dot after service_daemon is important: do not change it (the service won't start)
      :pid_file => "service_daemon.#{@channel.id}.pid",
      :log_file => "service_daemon_#{@channel.id}.log",
      :enabled => true
    )
    Queues.bind_ao @channel
  end

  def on_disable
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    proc.destroy if proc
  end

  def on_changed
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    proc.touch if proc
  end

  def on_pause
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    return unless proc

    proc.enabled = false
    proc.save!
  end

  def on_resume
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    return unless proc

    proc.enabled = true
    proc.save!
  end

  def on_destroy
    on_disable
  end

  def managed_process_name
    "#{@channel.kind}_daemon #{@channel.name}"
  end
end
