# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
class ServiceChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def on_create
    Queues.bind_ao @channel
    if @channel.enabled
      ManagedProcess.create!(
        :account_id => @channel.account.id,
        :name => managed_process_name,
        :start_command => "service_daemon_ctl.rb start -- #{Rails.env} #{@channel.id}",
        :stop_command => "service_daemon_ctl.rb stop -- #{Rails.env} #{@channel.id}",
        # The dot after service_daemon is important: do not change it (the service won't start)
        :pid_file => "service_daemon.#{@channel.id}.pid",
        :log_file => "service_daemon_#{@channel.id}.log",
        :enabled => true
      )
    end
  end

  def on_enable
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    return unless proc

    proc.enabled = true
    proc.save!
  end

  def on_disable
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    return unless proc

    proc.enabled = false
    proc.save!
  end

  def on_changed
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    proc.touch if proc
  end

  def on_pause
    on_disable
  end

  def on_resume
    on_enable
  end

  def on_destroy
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    proc.destroy if proc
  end

  def managed_process_name
    "#{@channel.kind}_daemon #{@channel.name}"
  end

  def has_connection?
    true
  end
end
