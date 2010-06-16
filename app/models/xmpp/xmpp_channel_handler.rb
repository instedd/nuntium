require 'xmpp4r/client'

class XmppChannelHandler < ServiceChannelHandler

  include Jabber
  
  def job_class
    SendXmppMessageJob
  end
  
  def service_name
    'xmpp_daemon'
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
