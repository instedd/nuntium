require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application
  
  has_many :qst_outgoing_messages
  has_many :cron_tasks, :as => :parent
  
  serialize :configuration, Hash
  
  validates_presence_of :name, :protocol, :kind, :application
  validate :handler_check_valid
  validate :name_is_unique_in_application
  
  before_save :handler_before_save
  
  # Channel directions
  Incoming = 1
  Outgoing = 2
  Both = Incoming + Outgoing
  
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
      eval(kind.capitalize + 'ChannelHandler.new(self)')
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
      'both'
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
  
  # TODO: Use validate uniquness toghether with scope
  def name_is_unique_in_application
    if self.new_record?
      other_channel = Channel.first(:conditions => ['application_id = ? AND name = ?', self.application_id, self.name])
      errors.add(:name, "has already been taken") if
        !other_channel.nil?
    end
  end
end
