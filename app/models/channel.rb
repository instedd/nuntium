require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application
  has_many :qst_outgoing_messages
  serialize :configuration
  
  validates_presence_of :name, :protocol, :kind, :application
  validate :password_not_blank, :password_confirmation, :name_is_unique_in_application
  
  before_save :hash_password
  
  def authenticate(password)
    self.configuration[:password] == Digest::SHA2.hexdigest(self.configuration[:salt] + password)
  end
  
  def clear_password
    if kind == 'qst'
      self.configuration[:salt] = nil
      self.configuration[:password] = nil
    end
  end
  
  private
  
  def hash_password
    if kind == 'qst'
      if !self.configuration[:salt].nil?
        return
      end
      
      self.configuration[:salt] = ActiveSupport::SecureRandom.base64(8)
      self.configuration[:password] = Digest::SHA2.hexdigest(self.configuration[:salt] + self.configuration[:password])
    end
  end
  
  def password_not_blank
    if kind == 'qst'
      errors.add(:password, "can't be blank") if
        self.configuration[:password].nil? || self.configuration[:password].chomp.empty?
    end
  end
  
  def password_confirmation
    if kind == 'qst'
      errors.add(:password, "doesn't match confirmation") if
        !self.configuration[:password_confirmation].nil? && self.configuration[:password] != self.configuration[:password_confirmation]
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
