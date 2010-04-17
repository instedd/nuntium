require 'xmpp4r/client'

class XmppChannelHandler < ChannelHandler

  include Jabber

  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end
  
  def handle_now(msg)
    handle msg
  end
  
  def create_job(msg)
    SendXmppMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def on_enable
    ManagedProcess.create!(
      :application_id => @channel.application.id,
      :name => managed_process_name,
      :start_command => "xmpp_daemon_ctl.rb start -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :stop_command => "xmpp_daemon_ctl.rb stop -- #{ENV["RAILS_ENV"]} #{@channel.id}",
      :pid_file => "xmpp_daemon.#{@channel.id}.pid",
      :log_file => "xmpp_daemon_#{@channel.id}.log",
      :enabled => true
    )
    Queues.bind_ao @channel
  end
  
  def on_disable
    proc = ManagedProcess.find_by_application_id_and_name @channel.application.id, managed_process_name
    proc.destroy if proc
  end
  
  def on_changed
    proc = ManagedProcess.find_by_application_id_and_name @channel.application.id, managed_process_name
    proc.touch if proc
  end
  
  def on_destroy
    on_disable
  end
  
  def managed_process_name
    "XMPP #{@channel.name}"
  end
  
  def check_valid
    check_config_not_blank :user, :domain, :password 
    
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank")
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end
  end
  
  def check_valid_in_ui
    c = @channel.configuration
  
    jid_str = "#{c[:user]}@#{c[:domain]}"
    jid_str << "/#{c[:resource]}" unless c[:resource].blank?
    jid = JID::new(jid_str)
    
    begin
      client = Client::new(jid)
      server = @channel.configuration[:server].blank? ? nil : @channel.configuration[:server]  
      client.connect server, @channel.configuration[:port]
      client.auth @channel.configuration[:password]
    rescue => e
      @channel.errors.add_to_base(e.message)
    ensure
      client.close
    end
  end
  
  def info
    c = @channel.configuration
    port_part = c[:port].to_i == 5222 ? '' : ":#{c[:port]}"
    "#{c[:user]}@#{c[:domain]}#{port_part}/#{c[:resource]}"
  end

end
