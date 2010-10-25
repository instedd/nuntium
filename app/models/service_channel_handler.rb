# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
class ServiceChannelHandler < ChannelHandler
  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def create_job(msg)
    job_class.new(@channel.account_id, @channel.id, msg.id)
  end

  def on_enable
    ManagedProcess.create!(
      :account_id => @channel.account.id,
      :name => managed_process_name,
      :start_command => "#{service_name}_ctl.rb start -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :stop_command => "#{service_name}_ctl.rb stop -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :pid_file => "#{service_name}.#{@channel.id}.pid",
      :log_file => "#{service_name}_#{@channel.id}.log",
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

  def on_unpause
    proc = ManagedProcess.find_by_account_id_and_name @channel.account.id, managed_process_name
    return unless proc

    proc.enabled = true
    proc.save!
  end

  def on_destroy
    on_disable
  end

  def job_class
    raise "The job_class method must be defined for #{self.class}"
  end

  def service_name
    raise "The service_name method must be defined for #{self.class}"
  end

  def managed_process_name
    "#{service_name} #{@channel.name}"
  end
end
