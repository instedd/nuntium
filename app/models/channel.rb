require 'digest/sha2'

class Channel < ActiveRecord::Base
  belongs_to :application
  has_many :qst_outgoing_messages
  serialize :configuration
  
  before_save :hash_password
  
  def authenticate(password)
    self.configuration[:password] == Digest::SHA2.hexdigest(self.configuration[:salt] + password)
  end
  
  private
  
  def hash_password
    if kind == :qst
      self.configuration[:salt] = ActiveSupport::SecureRandom.base64(8)
      self.configuration[:password] = Digest::SHA2.hexdigest(self.configuration[:salt] + self.configuration[:password])
    end
  end
end
