class MessengerChannel < Channel
  include GenericChannel

  configuration_accessor :page_access_token
  validates_presence_of :page_access_token

  def self.title
    "Facebook Messenger"
  end

  def self.default_protocol
    'sms'
  end

  def info
    page_access_token
  end
end