require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application
  
  has_many :qst_outgoing_messages
  has_many :cron_tasks, :as => :parent, :dependent => :destroy
  
  serialize :configuration, Hash
  
  validates_presence_of :name, :protocol, :kind, :application
  validates_uniqueness_of :name, :scope => :application_id, :message => 'Name has already been used by another channel in the application'
  
  validate :handler_check_valid
  before_save :handler_before_save
  after_save :handler_after_save
  after_create :handler_after_create
  
  # Channel directions
  Incoming = 1
  Outgoing = 2
  Both = Incoming + Outgoing

  include(CronTask::CronTaskOwner)
    
  def clear_password
    if self.handler.respond_to?(:clear_password)
      self.handler.clear_password
    end
  end
  
  def handle(msg)
    self.handler.handle msg
  end
  
  def handler
    if kind.nil?
      nil
    else
      eval(ActiveSupport::Inflector.camelize(kind) + 'ChannelHandler.new(self)')
    end
  end
  
  def info
    if self.handler.respond_to?(:info)
      return self.handler.info
    end
    return ''
  end
  
  def direction_text
    case direction
    when Incoming
      'incoming'
    when Outgoing
      'outgoing'
    when Both
      'bi-directional'
    end
  end
  
  def check_valid_in_ui
    @check_valid_in_ui = true
  end
    
  private
  
  def handler_check_valid
    if self.handler.respond_to?(:check_valid)
      self.handler.check_valid
    end
    if !@check_valid_in_ui.nil? and @check_valid_in_ui
      if self.handler.respond_to?(:check_valid_in_ui)
        self.handler.check_valid_in_ui
      end
    end
  end
  
  def handler_before_save
    if self.handler.respond_to?(:before_save)
      self.handler.before_save
    end
  end
  
  def handler_after_save
    if self.handler.respond_to?(:after_save)
      self.handler.after_save
    end
  end
  
  def handler_after_create
    if self.handler.respond_to?(:after_create)
      self.handler.after_create
    end
  end
  
end
