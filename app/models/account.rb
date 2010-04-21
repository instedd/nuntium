require 'digest/sha2'

class Account < ActiveRecord::Base
  
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  has_many :cron_tasks, :as => :parent, :dependent => :destroy
  has_many :alert_configurations
  
  serialize :configuration, Hash
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password, :interface
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :interface, :in => ['rss', 'qst_client', 'http_post_callback']
  validate :alert_well_formed
  
  before_save :hash_password 
  after_save :handle_tasks
  after_create :create_worker_queue
  after_save :bind_queue
  
  include(CronTask::CronTaskOwner)
  
  def self.find_by_id_or_name(id_or_name)
    account = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    account = self.find_by_name(id_or_name) if account.nil?
    account
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  # Route an AOMessage
  def route(msg, via_interface)
    return if duplicated? msg
    check_modified
  
    if @outgoing_channels.nil?
      @outgoing_channels = self.channels.all(:conditions => ['enabled = ? AND (direction = ? OR direction = ?)', true, Channel::Outgoing, Channel::Bidirectional])
    end
    
    if msg.new_record?
      # Fill msg missing fields
      msg.account_id ||= self.id
      msg.timestamp ||= Time.now.utc
    end
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.nil? ? '' : msg.to.protocol
    if protocol == ''
      msg.state = 'error'
      msg.save!
      logger.ao_message_received msg, via_interface
      logger.protocol_not_found_for_ao_message msg
      return true
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    # Find the preffered channel to route this message, if any,
    # based on the AcceptSource model
    preferred_channel = get_preferred_channel_name_for msg.to, @outgoing_channels
    
    # If no action triggered, or no custom logic, route to any channel
    router = MessageRouter.new(self, msg, channels, preferred_channel, via_interface, logger)
    router.route_to_any_channel
    true
  rescue => e
    # Log any errors and return false
    logger.error_routing_msg msg, e
    return false
  end
  
  def reroute(msg)
    msg.tries = 0
    msg.state = 'pending'
    self.route msg, 're-route'
  end
  
  # Accepts an ATMessage via a channel
  def accept(msg, via_channel)
    return if duplicated? msg
    check_modified
  
    msg.account_id = self.id
    msg.timestamp ||= Time.now.utc
    if !via_channel.nil? && via_channel.class == Channel
      msg.channel = via_channel
      msg.channel_id = via_channel.id
    end
    msg.state = 'queued'
    msg.save!
    
    # Update AddressSource if the account uses it
    if !self.configuration[:use_address_source].nil? && !via_channel.nil? && via_channel.class == Channel
      as = AddressSource.find_by_account_id_and_address self.id, msg.from
      if as.nil?
        AddressSource.create!(:account_id => self.id, :address => msg.from, :channel_id => via_channel.id) 
      else
        as.channel_id = via_channel.id
        as.save!
      end
    end
    
    # Check if callback interface is configured
    if self.interface == 'http_post_callback'
      Queues.publish_account self, SendPostCallbackMessageJob.new(msg.account_id, msg.id)
    end
    
    if 'ui' == via_channel
      logger.at_message_created_via_ui msg
    else
      logger.at_message_received_via_channel msg, via_channel if !via_channel.nil?
    end
  end
  
  def alert(message)
    # TODO send an email somehow...
    Rails.logger.info "Received alert for account #{self.name}: #{message}"
    logger.error message.to_s
  end
  
  def logger
    if @logger.nil?
      @logger = AccountLogger.new(self.id)
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
      return 'qst_client: ' << self.configuration[:url]
    when 'http_post_callback'
      return 'http_post_callback: ' << self.configuration[:url]
    end
  end
  
  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end
  
  def to_s
    name || id || 'unknown'
  end

  protected
  
  # Ensures tasks for this account are correct
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
  
  def create_worker_queue
    WorkerQueue.create!(:queue_name => Queues.account_queue_name_for(self), :working_group => 'fast', :ack => true)
  end
  
  def bind_queue
    Queues.bind_account self
  end
  
  private
  
  def hash_password
    if !self.salt.nil?
      return
    end
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
  
  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['account_id = ? and guid = ?', self.id, msg.guid])
  end
  
  def check_modified
    # Check whether the date of the account in the database is greater
    # than our date. If so, empty cached values.
    account = Account.find_by_id(self.id, :select => :updated_at)
    if !account.nil? && account.updated_at > self.updated_at
      @outgoing_channels = nil
    end
  end
  
  # Returns the Channel's name or nil
  def get_preferred_channel_name_for(address, outgoing_channels)
    return nil if self.configuration[:use_address_source].nil?
    as = AddressSource.first(:conditions => ['account_id = ? AND address = ?', self.id, address])
    return nil if as.nil?
    candidates = outgoing_channels.select{|x| x.id == as.channel_id}
    return nil if candidates.empty?
    return candidates[0].name
  end
  
  def alert_well_formed
    if (!self.configuration[:alert].nil? and self.configuration[:alert].strip.length > 0)
      begin
        instance_eval "def alert_function;\n" <<
          self.configuration[:alert] << ";\n" << 
        "end;"
      rescue Exception => e
        self.errors.add(:alert, fix_error("error: #{e.message}"))
      end
    end
  end
  
end

# If many dots are sent to a validation error, an "interning empty string" error
# happens. This is a hack/fix for this.
def fix_error(msg)
  msg.gsub('.', ' ')
end

class MessageRouter 

  attr_reader :msg

  def initialize(account, msg, channels, preferred_channel, via_interface, logger)
    @account = account
    @msg = msg
    @channels = channels
    @preferred_channel = preferred_channel
    @via_interface = via_interface
    @logger = logger
  end
  
  def route_to_any_channel
    if !@preferred_channel.nil?
      channels = @channels.select{|x| x.name == @preferred_channel}
    else
      channels = @channels
    end
    
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      @logger.no_channel_found_for_ao_message @msg.to.protocol, @msg
      return
    end
    
    # Select channels with less or equal metric than the other channels
    channels = channels.select{|c| channels.all?{|x| c.metric <= x.metric }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]

    push_message_into channel
  end
  
  def push_message_into(channel)
    # Save the message
    @msg.channel = channel
    @msg.state = 'queued'
    @msg.save!
    
    # Do some logging
    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_handled_by_channel @msg, channel
    
    # Let the channel handle the message
    channel.handle @msg
  end
end
