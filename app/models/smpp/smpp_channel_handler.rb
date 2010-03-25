class SmppChannelHandler < ChannelHandler
  def handle(msg)
    if @channel.throttle.nil?
      Delayed::Job.enqueue create_job(msg)
    else
      ThrottledJob.enqueue @channel.id, create_job(msg)
    end
  end
  
  def handle_now
    create_job(msg).perform
  end
  
  def create_job(msg)
    SendSmppMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def on_enable
    ManagedProcess.create!(
      :application_id => @channel.application.id,
      :name => managed_process_name,
      :start_command => "drb_smpp_daemon_ctl.rb start -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :stop_command => "drb_smpp_daemon_ctl.rb stop -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :pid_file => "drb_smpp_daemon.#{@channel.id}.pid",
      :log_file => "drb_smpp_daemon_#{@channel.id}.log"
    )
  end
  
  def on_disable
    proc = ManagedProcess.find_by_application_id_and_name @channel.application.id, managed_process_name
    proc.delete if proc
  end
  
  def on_changed
    proc = ManagedProcess.find_by_application_id_and_name @channel.application.id, managed_process_name
    proc.touch if proc
  end
  
  def on_destroy
    on_disable
  end
  
  def managed_process_name
    "SMPP #{@channel.name}"
  end
  
  def check_valid
    check_config_not_blank :host, :system_type
    
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank")
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end
    
    [:source_ton, :source_npi, :destination_ton, :destination_npi].each do |sym|
      if @channel.configuration[sym].nil?
        @channel.errors.add(sym, "can't be blank")
      else
        s = @channel.configuration[sym].to_i
        if s < 0 || s > 7
          @channel.errors.add(sym, "must be a number between 0 and 7")
        end
      end
    end
  
    check_config_not_blank :user, :password, :default_mo_encoding, :mt_encodings, :mt_csms_method
  end
  
  def check_valid_in_ui
    config = @channel.configuration
    
    # what kind of validation should we put here?
    # what if the smpp connection require a vpn?

  end
  
  def info
    c = @channel.configuration
    "#{c[:user]}@#{c[:host]}:#{c[:port]}"
  end
end
