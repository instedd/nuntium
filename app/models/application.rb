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
  validates_inclusion_of :interface, :in => ['rss', 'qst_client']
  
  before_save :hash_password 
  after_save :handle_tasks
  
  include(CronTask::CronTaskOwner)
  include(HaitiFixes)
  
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
      @outgoing_channels = self.channels.all(:conditions => ['enabled = ? AND (direction = ? OR direction = ?)', true, Channel::Outgoing, Channel::Both])
    end
    
    if msg.new_record?
      # Fill msg missing fields
      msg.application_id ||= self.id
      msg.timestamp ||= Time.now.utc
    end
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.protocol
    if protocol == ''
      msg.state = 'error'
      msg.save!
      logger.ao_message_received msg, via_interface
      logger.protocol_not_found_for_ao_message msg
      return true
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    # See if there's a custom AO routing logic 
    if !self.ao_routing.nil? && self.ao_routing.strip.length != 0
      # Create ao_routing function is not yet defined
      if !respond_to?(:ao_routing_function)
        instance_eval 'def ao_routing_function(msg, channels);' + self.ao_routing + '; end;'
      end
      
      routing = ao_routing_function(msg, channels)
      if !msg.application.nil? and msg.application.id != self.id
        msg.state = 'pending'
        msg.save!
        logger.ao_message_received msg, via_interface
        logger.ao_message_routed_to_application msg, msg.application
        msg.application.route msg, {:application => self}
        return
      end
      
      if routing.nil?
        # Routing logic was not overriden, just a transform was applied
      elsif routing.class == String
        # Route to channel by name
        channels = channels.select{|x| x.name == routing}
      elsif routing.class == Array && routing.length > 0
        if routing[0].class == String
          channels = channels.select{|x| routing.include?(x.name)}
        elsif routing[0].class == Channel
          channels = routing
        end
      end
    end
    
    if channels.empty?
      msg.state = 'error'
      msg.save!
      
      logger.ao_message_received msg, via_interface
      logger.no_channel_found_for_ao_message protocol, msg
      return true
    end
    
    # Select channels with less or equal metric than the other channels
    channels = channels.select{|c| channels.all?{|x| c.metric <= x.metric }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]

    # Now save the message
    msg.channel_id = channel.id
    msg.state = 'queued'
    msg.save!
    
    logger.ao_message_received msg, via_interface
    logger.ao_message_handled_by_channel msg, channel
    
    # Let the channel handle the message
    channel.handle msg
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
    self.configuration ||= {}
    self.configuration[:last_at_guid] = value
    self.save
  end
  
  def set_last_ao_guid(value)
    self.configuration ||= {}
    self.configuration[:last_ao_guid] = value
    self.save
  end
  
  def interface_description
    case interface
    when 'rss'
      return 'rss'
    when 'qst_client'
      return 'qst_client: ' + self.configuration[:url]
    end
  end

  protected
  
  # Ensures tasks for this application are correct
  def handle_tasks(force = false)
    if self.interface_changed? || force
      case self.interface
        when 'qst_client'
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
