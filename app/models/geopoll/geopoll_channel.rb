class GeopollChannel < Channel
  include GenericChannel

  configuration_accessor :auth_token
  validates_presence_of :auth_token
  handle_password_change :auth_token

  def self.default_protocol
    'sms'
  end

  def info
    "<a target=\"_blank\" href=\"/geopoll/#{self.id}/balance\">view credit</a>".html_safe
  end
end
