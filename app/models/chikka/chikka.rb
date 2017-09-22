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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class Chikka
  # From https://api.chikka.com/docs/handling-messages#send-sms
  SEND_STATUS = {
    '200' => [:success, 'Accepted'],
    '400' => [:message_error, 'Bad Request'], # FIXME: :message or :permanent depends on the description
    '401' => [:system_error, 'Unauthorized'],
    '403' => [:message_error, 'Method Not Allowed'],
    '404' => [:message_error, 'URI Not Found'],
    '500' => [:temporal_error, 'General System Error']
  }

  def self.send_status(status)
    SEND_STATUS[status['status'].to_s] || [:system_error, "Unknown error code: #{status['status']} - #{status['message']}"]
  end
end
