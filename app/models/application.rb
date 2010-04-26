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
  def route(msg, via_interface)
    return if duplicated? msg
    check_modified
  
    if @outgoing_channels.nil?
      @outgoing_channels = self.account.channels.all(:conditions => ['enabled = ? AND (direction = ? OR direction = ?)', true, Channel::Outgoing, Channel::Bidirectional])
    end
    
    if msg.new_record?
      # Fill msg missing fields
      msg.account_id ||= self.account.id
      msg.application_id = self.id
      msg.timestamp ||= Time.now.utc
    end
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.nil? ? '' : msg.to.protocol
    if protocol == ''
      msg.state = 'error'
      msg.save!
      account.logger.ao_message_received msg, via_interface
      account.logger.protocol_not_found_for_ao_message msg
      return true
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    # Find the preffered channel to route this message, if any,
    # based on the AcceptSource model
    preferred_channel = get_preferred_channel_name_for msg.to, @outgoing_channels
    
    # If no action triggered, or no custom logic, route to any channel
    router = MessageRouter.new(self, msg, channels, preferred_channel, via_interface, account.logger)
    router.route_to_any_channel
    true
  rescue => e
    # Log any errors and return false
    account.logger.error_routing_msg msg, e
    return false
  end
  
  def reroute(msg)
    msg.tries = 0
    msg.state = 'pending'
    self.route msg, 're-route'
  end
  
  def accept(msg, via_channel)
    msg.application_id = self.id
  
    # Update AddressSource if the account uses it
    if !self.configuration[:use_address_source].nil? && !via_channel.nil? && via_channel.class == Channel
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
      account.logger.at_message_created_via_ui msg
    else
      account.logger.at_message_received_via_channel msg, via_channel if !via_channel.nil?
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
  
  def alert(alert_msg)
    account.alert alert_msg
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
  
  # Returns the Channel's name or nil
  def get_preferred_channel_name_for(address, outgoing_channels)
    return nil if self.configuration[:use_address_source].nil?
    as = AddressSource.first(:conditions => ['application_id = ? AND address = ?', self.id, address])
    return nil if as.nil?
    candidates = outgoing_channels.select{|x| x.id == as.channel_id}
    return nil if candidates.empty?
    return candidates[0].name
  end
  
  def hash_password
    return if self.salt.present?
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
end
