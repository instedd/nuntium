require 'xmpp4r/client'

class XmppChannelHandler < ServiceChannelHandler

  include Jabber

  def self.title
    "XMPP"
  end

  def jid
    c = @channel.configuration
    jid_str = "#{c[:user]}@#{c[:domain]}"
    jid_str << "/#{c[:resource]}" unless c[:resource].blank?
    JID::new(jid_str)
  end

  def server
    @channel.configuration[:server].blank? ? nil : @channel.configuration[:server]
  end

  def check_valid
    check_config_not_blank :user, :domain, :password
    check_config_port
  end

  def check_valid_in_ui
    begin
      client = Client::new(jid)
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
