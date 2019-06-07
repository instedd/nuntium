class GeoPollChannel < Channel
  include GenericChannel

  configuration_accessor :account_sid, :auth_token, :from
  validates_presence_of :account_sid, :auth_token, :from

  def self.default_protocol
    'sms'
  end

end