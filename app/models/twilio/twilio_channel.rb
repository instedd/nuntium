class TwilioChannel < Channel
  include GenericChannel

  configuration_accessor :account_sid, :auth_token, :from, :incoming_password
  validates_presence_of :account_sid, :auth_token, :from, :incoming_password

  def self.default_protocol
    'sms'
  end

  def info
    account_sid
  end
end
