# Copyright (C) 2009-2017, InSTEDD
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

class ChikkaChannel < Channel
  include GenericChannel

  configuration_accessor :shortcode, :client_id, :secret_key, :secret_token
  validates_presence_of :shortcode, :client_id, :secret_key, :secret_token

  handle_password_change :secret_key

  def self.default_protocol
    'sms'
  end

end
