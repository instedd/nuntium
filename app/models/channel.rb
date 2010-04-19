require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application, :touch => :updated_at
  
  has_many :qst_outgoing_messages
  has_many :address_sources
  has_many :cron_tasks, :as => :parent, :dependent => :destroy # TODO: Tasks are not being destroyed
  has_one :alert_configuration
  
  serialize :configuration, Hash
  
  validates_presence_of :name, :protocol, :kind, :application
  validates_uniqueness_of :name, :scope => :application_id, :message => 'Name has already been used by another channel in the application'
  validates_numericality_of :throttle, :allow_nil => true, :only_integer => true, :greater_than_or_equal_to => 0
  
  validate :handler_check_valid
  before_save :handler_before_save
  after_create :handler_after_create
  after_update :handler_after_update
  before_destroy :handler_before_destroy
  
  # Channel directions
  Incoming = 1
  Outgoing = 2
  Bidirectional = Incoming + Outgoing

  include(CronTask::CronTaskOwner)
    
  def clear_password
    self.handler.clear_password if self.handler.respond_to?(:clear_password)
  end
  
  def handle(msg)
    self.handler.handle msg
  end
  
  def handle_now(msg)
    self.handler.handle_now msg
  end
  
  def accept(msg)
    application.accept msg, self
  end
  
  def alert(message)
    # TODO send an email somehow...
    Rails.logger.info "Received alert for channel #{self.name} in application #{self.application.name}: #{message}"
    ApplicationLogger.exception_in_channel self, message
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

end
