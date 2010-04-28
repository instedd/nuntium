require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :account, :touch => :updated_at
  
  has_many :qst_outgoing_messages
  has_many :address_sources
  has_many :cron_tasks, :as => :parent, :dependent => :destroy # TODO: Tasks are not being destroyed
  
  serialize :configuration, Hash
  serialize :custom_attributes
  serialize :at_rules
  
  validates_presence_of :name, :protocol, :kind, :account
  validates_uniqueness_of :name, :scope => :account_id, :message => 'has already been used by another channel in the account'
  validates_numericality_of :throttle, :allow_nil => true, :only_integer => true, :greater_than_or_equal_to => 0
  
  validate :handler_check_valid
  before_save :handler_before_save
  after_create :handler_after_create
  after_update :handler_after_update
  before_destroy :handler_before_destroy
  
  before_destroy :clear_cache 
  after_save :clear_cache
  
  # Channel directions
  Incoming = 1
  Outgoing = 2
  Bidirectional = Incoming + Outgoing

  include(CronTask::CronTaskOwner)
  
  def route_ao(msg, via_interface)
    # Save the message
    msg.channel = self
    msg.state = 'queued'
    msg.save!
    
    # Do some logging
    logger.ao_message_received msg, via_interface
    logger.ao_message_handled_by_channel msg, self
    
    # Handle the message
    handle msg
  end
  
  def can_route_ao?(msg)
    # Check that each custom attribute is present in this channel's
    # custom attributes
    msg.custom_attributes.each do |key, values|
      values = [values] unless values.kind_of? Array
    
      channel_values = custom_attributes[key]
      next unless channel_values.present?
      
      channel_values = [channel_values] unless channel_values.kind_of? Array
      
      return false unless values.any?{|v| channel_values.include? v}
    end
  end
  
  def self.find_all_by_account_id(account_id)
    channels = Rails.cache.read cache_key(account_id)
    if not channels
      channels = Channel.all :conditions => ['account_id = ?', account_id]
      Rails.cache.write cache_key(account_id), channels
    end
    channels
  end
  
  def is_outgoing?
    direction == Outgoing || direction == Bidirectional
  end
  
  def is_incoming?
    direction == Incoming || direction == Bidirectional
  end
  
  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end
  
  def custom_attributes
    self[:custom_attributes] = ActiveSupport::OrderedHash.new if self[:custom_attributes].nil?
    self[:custom_attributes]
  end
    
  def clear_password
    self.handler.clear_password if self.handler.respond_to?(:clear_password)
  end
  
  def handle(msg)
    self.handler.handle msg
  end
  
  def handle_now(msg)
    self.handler.handle_now msg
  end
  
  def route_at(msg)
    account.route_at msg, self
  end
  
  def alert(message)
    # TODO send an email somehow...
    Rails.logger.info "Received alert for channel #{self.name} in account #{self.account.name}: #{message}"
    AccountLogger.exception_in_channel self, message
  end
  
  def handler
    if kind.nil?
      nil
    else
      eval(ActiveSupport::Inflector.camelize(kind) + 'ChannelHandler.new(self)')
    end
  end
  
  def info
    return self.handler.info if self.handler.respond_to?(:info)
    return ''
  end
  
  def direction_text
    case direction
    when Incoming
      'incoming'
    when Outgoing
      'outgoing'
    when Bidirectional
      'bi-directional'
    end
  end
  
  def check_valid_in_ui
    @check_valid_in_ui = true
  end
  
  def throttle_opt
    self.throttle.nil? ? 'off' : 'on'
  end
  
  def logger
    account.logger
  end
  
  private
  
  def handler_check_valid
    self.handler.check_valid if self.handler.respond_to?(:check_valid)
    if !@check_valid_in_ui.nil? and @check_valid_in_ui
      self.handler.check_valid_in_ui if self.handler.respond_to?(:check_valid_in_ui)
    end
  end
  
  def handler_before_save
    self.handler.before_save
    true
  end
  
  def handler_after_create
    if self.enabled
      self.handler.on_enable
    else
      self.handler.on_disable
    end
  end
  
  def handler_after_update
    if self.enabled_changed?
      if self.enabled
        self.handler.on_enable
      else
        self.handler.on_disable
      end
    end
    self.handler.on_changed
    true
  end

  def handler_before_destroy
    self.handler.on_destroy
    true
  end
  
  def clear_cache
    Rails.cache.delete Channel.cache_key(account_id)
    true
  end
  
  def self.cache_key(account_id)
    "account_#{account_id}_channels"
  end

end
