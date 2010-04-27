require 'digest/sha2'

class Application < ActiveRecord::Base
  belongs_to :account
  has_many :ao_messages
  has_many :at_messages
  has_many :address_sources
  has_many :cron_tasks, :as => :parent, :dependent => :destroy
  
  attr_accessor :password_confirmation
  
  validates_presence_of :account_id
  validates_presence_of :name, :password, :interface
  validates_confirmation_of :password
  validates_uniqueness_of :name, :scope => :account_id, :message => 'has already been used by another application in the account'
  validates_inclusion_of :interface, :in => ['rss', 'qst_client', 'http_post_callback']
  validates_presence_of :configuration_url, :unless => :is_rss
  
  serialize :configuration, Hash
  
  before_save :hash_password
  
  after_save :handle_tasks
  after_create :create_worker_queue
  after_save :bind_queue
  
  include(CronTask::CronTaskOwner)
  
  # Route an AOMessage
  def route_ao(msg, via_interface)
    return if duplicated? msg
    check_modified
  
    # Get all outgoing enabled channels
    if @outgoing_channels.nil?
      @outgoing_channels = self.account.channels.all(:conditions => ['enabled = ? AND (direction = ? OR direction = ?)', true, Channel::Outgoing, Channel::Bidirectional])
      @outgoing_channels.each{|c| c.account = self.account}
    end
    
    # Fill some fields
    if msg.new_record?
      msg.account_id ||= self.account.id
      msg.application_id = self.id
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
    
    # Save mobile number information
    MobileNumber.update msg.to.mobile_number, msg.country, msg.carrier if protocol == 'sms'
    
    # Find channels that handle that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    # Find the preffered channel to route this message, if any,
    # based on the last channel used to receive an AT for the given address
    preferred_channel = get_preferred_channel msg.to, @outgoing_channels
    if preferred_channel
      preferred_channel.route_ao msg, via_interface
      return true
    end
    
    # Exit if no candidate channel 
    if channels.empty?
      msg.state = 'error'
      msg.save!
      
      logger.ao_message_received msg, via_interface
      logger.no_channel_found_for_ao_message protocol, msg
      return true
    end
    
    # Select channels with less or equal priority than the other channels
    channels = channels.select{|c| channels.all?{|x| c.priority <= x.priority }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]
    
    channel.route_ao msg, via_interface
    true
  rescue => e
    # Log any errors and return false
    logger.error_routing_msg msg, e
    return false
  end
  
  def reroute_ao(msg)
    msg.tries = 0
    msg.state = 'pending'
    self.route_ao msg, 're-route'
  end
  
  def route_at(msg, via_channel)
    msg.application_id = self.id
  
    # Update AddressSource if desireda and if it the channel is bidirectional
    if use_address_source? and via_channel and via_channel.class == Channel and via_channel.direction == Channel::Bidirectional
      as = AddressSource.find_by_application_id_and_address self.id, msg.from
      if as.nil?
        AddressSource.create!(:account_id => account.id, :application_id => self.id, :address => msg.from, :channel_id => via_channel.id) 
      else
        as.channel_id = via_channel.id
        as.save!
      end
    end
    
    # Check if callback interface is configured
    if self.interface == 'http_post_callback'
      Queues.publish_application self, SendPostCallbackMessageJob.new(msg.application_id, msg.id)
    end
    
    msg.save!
    
    if 'ui' == via_channel
      logger.at_message_created_via_ui msg
    else
      logger.at_message_received_via_channel msg, via_channel if !via_channel.nil?
    end
  end
  
  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end
  
  def configuration_url; configuration[:url]; end;
  def configuration_user; configuration[:user]; end;
  def configuration_password; configuration[:password]; end;
  
  def is_rss
    self.interface == 'rss'
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  def set_last_at_guid(value)
    self.configuration[:last_at_guid] = value
    self.save
  end
  
  def set_last_ao_guid(value)
    self.configuration[:last_ao_guid] = value
    self.save
  end
  
  def use_address_source?
    configuration[:use_address_source] == '1'
  end
  
  def use_address_source=(value)
    if value
      configuration[:use_address_source] = value == '1'
    else
      configuration.delete :use_address_source
    end
  end
  
  def strategy
    configuration[:strategy] || 'broadcast'
  end
  
  def strategy=(value)
    configuration[:strategy] = value
  end
  
  def strategy_description
    Application.strategy_description(strategy)
  end
  
  def self.strategy_description(strategy)
    case strategy
    when 'broadcast'
      'Boradcast'
    when 'single_priority'
      'Single (priority)'
    end
  end
  
  def interface_description
    case interface
    when 'rss'
      return 'Rss'
    when 'qst_client'
      return 'QST client: ' << self.configuration[:url]
    when 'http_post_callback'
      return 'HTTP POST callback: ' << self.configuration[:url]
    end
  end
  
  def alert(alert_msg)
    account.alert alert_msg
  end
  
  def logger
    account.logger
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
    WorkerQueue.create!(:queue_name => Queues.application_queue_name_for(self), :working_group => 'fast', :ack => true)
  end
  
  def bind_queue
    Queues.bind_application self
  end
  
  private
  
  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['application_id = ? and guid = ?', self.id, msg.guid])
  end
  
  def check_modified
    # Check whether the date of the account in the database is greater
    # than our date. If so, empty cached values.
    acc = Account.find_by_id(account.id, :select => :updated_at)
    if !acc.nil? && acc.updated_at > self.account.updated_at
      @outgoing_channels = nil
    end
  end
  
  def get_preferred_channel(address, outgoing_channels)
    return nil unless use_address_source?
    as = AddressSource.first(:conditions => ['application_id = ? AND address = ?', self.id, address])
    return nil if as.nil?
    candidates = outgoing_channels.select{|x| x.id == as.channel_id}
    return nil if candidates.empty?
    return candidates[0]
  end
  
  def hash_password
    return if self.salt.present?
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
end
