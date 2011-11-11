require 'xmpp4r/client'

class XmppChannel < Channel
  include ServiceChannel
  include Jabber

  configuration_accessor :user, :password, :domain, :resource, :server, :status
  configuration_accessor :port, :default => 5222
  configuration_accessor :send_if_user_is_offline, :default => true

  validates_presence_of :user, :domain, :password
  validates_numericality_of :port, :greater_than => 0

  def self.title
    "XMPP"
  end

  def self.default_protocol
    'xmpp'
  end

  def jid
    jid = "#{user}@#{domain}"
    jid << "/#{resource}" if resource.present?
    jid
  end

  def server
    configuration[:server].presence
  end

  def check_valid_in_ui
    with_xmpp4r_client
    true
  rescue => e
    errors.add :base, e.message
    false
  end

  def info
    port_part = port.to_i == 5222 ? '' : ":#{port}"
    "#{user}@#{domain}#{port_part}/#{resource}"
  end

  def send_if_user_is_offline?
    send_if_user_is_offline.to_b
  end

  def add_contact(jid)
    with_xmpp4r_client do |client|
      presence = Jabber::Presence.new
      presence.to = jid
      presence.type = :subscribe
      client.send presence
    end
  end

  def with_xmpp4r_client
    client = Client::new JID::new(jid)
    client.connect server, port
    client.auth password
    yield client if block_given?
  ensure
    client.close
  end
end
