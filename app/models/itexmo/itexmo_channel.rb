# Copyright (C) 2009-2020, InSTEDD
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class ItexmoChannel < Channel
  include GenericChannel

  configuration_accessor :email, :api_code, :incoming_password, :api_password
  validates_presence_of :email, :api_code, :incoming_password, :api_password
  before_validation :generate_incoming_password
  handle_password_change :api_code
  handle_password_change :incoming_password
  handle_password_change :api_password

  def generate_incoming_password
    self.incoming_password ||= Devise.friendly_token
  end

  def self.default_protocol
    'sms'
  end
end
