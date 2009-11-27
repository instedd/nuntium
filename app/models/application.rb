require 'digest/sha2'

class Application < ActiveRecord::Base
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  
  serialize :configuration, Hash
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password, :interface
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :interface, :in => ['rss', 'qst']
  
  before_save :hash_password
  
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
    if @outgoing_channels.nil?
      @outgoing_channels = self.channels.all(:conditions => ['direction = ? OR direction = ?', Channel::Outgoing, Channel::Both])
    end
    
    # Fill msg missing fields
    msg.application_id ||= self.id
    msg.timestamp ||= Time.now.utc
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.protocol
    if protocol.nil?
      msg.state = 'error'
      msg.save!
      logger.protocol_not_found_for msg
      return
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    if channels.empty?
      msg.state = 'error'
      msg.save!
      logger.no_channel_found_for protocol, msg
      return
    end

    # Now save the message
    msg.state = 'queued'
    msg.save!
    
    if channels.length > 1
      logger.more_than_one_channel_found_for protocol, msg
    end
    
    # Let the channel handle the message
    channels[0].handle msg
  end
  
  def logger
    if @logger.nil?
      @logger = ApplicationLogger.new(self.id)
    end
    @logger
  end
  
  def clear_password
    self.salt = nil
    self.password = nil
    self.password_confirmation = nil
  end
  
  def set_last_at_guid(value)
    if self.configuration.nil?
      self.configuration = { :last_at_guid => value }
      self.save
    elsif self.configuration[:last_at_guid] != value
      self.configuration[:last_at_guid] = value
      self.save
    end
  end
  
  def set_last_ao_guid(value)
    if self.configuration.nil?
      self.configuration = { :last_ao_guid => value }
      self.save
    elsif self.configuration[:last_ao_guid] != value
      self.configuration[:last_ao_guid] = value
      self.save
    end
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
