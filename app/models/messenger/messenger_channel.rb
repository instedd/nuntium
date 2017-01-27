class MessengerChannel < Channel
  include GenericChannel


  def self.title
    "Facebook Messenger"
  end

  def self.default_protocol
    'sms'
  end

  def info
    email
  end
end