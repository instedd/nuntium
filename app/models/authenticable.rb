# Copyright (C) 2009-2012, InSTEDD
# 
# This file is part of Nuntium.
# 
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

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
