require 'digest/sha2'

class Application < ActiveRecord::Base
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  
  before_save :hash_password
  
  def self.find_by_name(name)
    Application.first(:conditions => ['name = ?', name]) 
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
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
