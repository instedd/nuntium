require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application
  has_many :qst_outgoing_messages
  serialize :configuration
  
  validates_presence_of :name, :protocol, :kind, :application
  validate :handler_check_valid
  validate :name_is_unique_in_application
  
  before_save :handler_before_save
  
  DirectionIncoming = 1
  DirectionOutgoing = 2
  DirectionBoth = DirectionIncoming + DirectionOutgoing
  
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
  
  private
  
  def handler_check_valid
    if self.handler.respond_to?(:check_valid)
      self.handler.check_valid
    end
  end
  
  def handler_before_save
    if self.handler.respond_to?(:before_save)
      self.handler.before_save
    end
  end
  
  def name_is_unique_in_application
    if self.new_record?
      other_channel = Channel.first(:conditions => ['application_id = ? AND name = ?', self.application_id, self.name])
      errors.add(:name, "has already been taken") if
        !other_channel.nil?
    end
  end
end
