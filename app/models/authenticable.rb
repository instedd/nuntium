module Authenticable
  extend ActiveSupport::Concern

  included do
    before_create :hash_password
    before_validation :reset_password, :if => lambda { persisted? && password.blank? && password_confirmation.blank? }
    before_update :hash_password, :if => lambda { password.present? && password_changed? }
  end

  module InstanceMethods
    def authenticate(password)
      self.password == encode_password(self.salt + password)
    end

    def reset_password
      self.password = self.password_was
      self.password_confirmation = self.password
    end

    def hash_password
      self.salt = ActiveSupport::SecureRandom.base64(8)
      self.password = encode_password(self.salt + self.password) if self.password
      self.password_confirmation = encode_password(self.salt + self.password_confirmation) if self.password_confirmation
    end

    def encode_password(str)
      Digest::SHA2.hexdigest str
    end
  end
end
