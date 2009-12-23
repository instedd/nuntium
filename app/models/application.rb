require 'digest/sha2'

class Application < ActiveRecord::Base
  
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  has_many :cron_tasks, :as => :parent, :dependent => :destroy
  
  serialize :configuration, Hash
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password, :interface
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :interface, :in => ['rss', 'qst']
  
  before_save :hash_password 
  after_save :handle_tasks
  
  include(CronTask::CronTaskOwner)
  
  def self.find_by_id_or_name(id_or_name)
    app = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    app = self.find_by_name(id_or_name) if app.nil?
    app
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  def last_at_message
    ATMessage.last(:order => :timestamp, :conditions => ['application_id = ?', self.id])
  end
  
  # Route an AOMessage
  def route(msg, via_interface)
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
      logger.ao_message_received msg, via_interface
      logger.protocol_not_found_for_ao_message msg
      return true
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    if channels.empty?
      msg.state = 'error'
      msg.save!
      logger.ao_message_received msg, via_interface
      logger.no_channel_found_for_ao_message protocol, msg
      return true
    end

    # Now save the message
    msg.state = 'queued'
    msg.save!
    
    logger.ao_message_received msg, via_interface
    
    if channels.length > 1
      logger.more_than_one_channel_found_for protocol, msg
    end
    
    logger.ao_message_handled_by_channel msg, channels[0]
    
    # Let the channel handle the message
    channels[0].handle msg
    true
    
  rescue => e
    # Log any errors and return false
    logger.error_routing_msg msg, e
    return false
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
    self.configuration[:cred_pass] = nil unless self.configuration.nil?
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
  
  def interface_description
    case interface
    when 'rss'
      return 'rss'
    when 'qst'
      return self.configuration[:url]
    end
  end

  protected
  
  # Ensures tasks for this application are correct
  def handle_tasks(force = false)
    if self.interface_changed? || force
      case self.interface
        when 'qst'
          create_task('qst-push', QST_PUSH_INTERVAL, PushQstMessageJob.new(self.id))
          create_task('qst-pull', QST_PULL_INTERVAL, PullQstMessageJob.new(self.id))
      else
        drop_task('qst-push')
        drop_task('qst-pull')
      end
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
