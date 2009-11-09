require 'digest/sha2'

class Application < ActiveRecord::Base
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  
  before_save :hash_password
  
  def self.find_by_name(name)
    Application.first(:conditions => ['name = ?', name]) 
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  def last_at_message
    ATMessage.last(
        :order => :timestamp, 
        :conditions => ['application_id = ?', self.id])
  end
  
  # Route an AOMessage
  def route(msg)
    if @incoming_channels.nil?
      @incoming_channels = self.channels.all(:conditions => ['direction = ? OR direction = ?', Channel::Incoming, Channel::Both])
    end
    
    app_logger = ApplicationLogger.new(self)
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.protocol
    if protocol.nil?
      app_logger.protocol_not_found_for msg
      return
    end
    
    # Find channel that handles that protocol
    channels = @incoming_channels.select {|x| x.protocol == protocol}
    
    if channels.empty?
      app_logger.no_channel_found_for protocol, msg
      return
    end

    # Now save the message
    msg.state = 'queued'
    msg.save
    
    if channels.length > 1
      app_logger.more_than_one_channel_found_for protocol, msg
    end
    
    # Let the channel handle the message
    channels[0].handle msg
    
    app_logger.close
  end
  
  def clear_password
    self.salt = nil
    self.password = nil
    self.password_confirmation = nil
  end
  
  private
  
  def hash_password
    if !self.salt.nil?
      return
    end
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
end
