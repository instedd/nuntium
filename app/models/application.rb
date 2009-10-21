require 'digest/sha2'

class Application < ActiveRecord::Base
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  
  before_save :hash_password
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  private
  
  def hash_password
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
end
