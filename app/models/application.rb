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
        instance_eval ao_routing_function_template self.ao_routing
      end

      had_actions = ao_routing_function(self, msg, channels, via_interface, logger)
      return true if had_actions
    end
    
    msg = MessageRouter.new(self, msg, channels, via_interface, logger)
    msg.route_to_any_channel
    true
  rescue => e
    # Log any errors and return false
    logger.error_routing_msg msg, e
    return false
  end
  
  def ao_routing_function_template(code)
    s = <<-END_OF_FUNC
      def ao_routing_function(app, msg, channels, via_interface, logger)
        msg = MessageRouter.new(app, msg, channels, via_interface, logger)
        
        #{code}
        msg.executed_action
      end
END_OF_FUNC
    s
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

class MessageRouter 

  attr_reader :executed_action
  attr_reader :msg

  def initialize(application, msg, channels, via_interface, logger)
    @application = application
    @msg = msg
    @channels = channels
    @via_interface = via_interface
    @logger = logger
    @executed_action = false
  end
  
  def from; @msg.from; end
  def from=(value); @msg.from = value; end
  def to; @msg.to; end
  def to=(value); @msg.to= value; end
  def subject; @msg.subject; end
  def subject=(value); @msg.subject = value; end
  def body; @msg.body; end
  def body=(value); @msg.body = value; end
  def guid; @msg.guid; end
  def guid=(value); @msg.guid = value; end
  def timestamp; @msg.timestamp; end
  def timestamp=(value); @msg.timestamp = value; end
  
  def route_to_channel(name)
    @executed_action = true
  
    channels = @channels.select{|x| x.name == name}
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      @logger.channel_not_found @msg, name
      return
    end
    
    push_message_into channels[0]
  end
  
  def route_to_any_channel(*names)
    @executed_action = true
  
    if names.length > 0
      channels = @channels.select{|x| names.include?(x.name)}
    else
      channels = @channels
    end
    
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      if names.length == 0
        @logger.no_channel_found_for_ao_message @msg.to.protocol, @msg
      else
        @logger.channel_not_found @msg, names
      end
      return
    end
    
    # Select channels with less or equal metric than the other channels
    channels = channels.select{|c| channels.all?{|x| c.metric <= x.metric }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]

    push_message_into channel
  end
  
  def route_to_application(name)
    @executed_action = true
    
    @msg.application = Application.find_by_name name
    @msg.state = 'pending'
    @msg.save!

    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_routed_to_application @msg, @msg.application
    @msg.application.route @msg, {:application => @application}
  end
  
  def push_message_into(channel)
    # Save the message
    @msg.channel_id = channel.id
    @msg.state = 'queued'
    @msg.save!
    
    # Do some logging
    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_handled_by_channel @msg, channel
    
    # Let the channel handle the message
    channel.handle @msg
  end
  
  def copy
    @executed_action = true
  
    other = MessageRouter.new(@application, @msg.clone, @channels, @via_interface, @logger)
    yield other
  end
end