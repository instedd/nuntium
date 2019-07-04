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

class Geopoll
  BASE_URL = 'https://api-external.geopoll.com'
  SMS_SEND_URL = "#{BASE_URL}/api/sms/send"

  def self.error_messsage(error)
    status_code = error["Status"]["Code"]
    error_message = error["Status"]["Message"]
    # FIXME: check if error is PermanentException or MessageException
    Exception.new("#{status_code} - #{error_message}")
  end

  def self.send_status(status)

    case status['status'].to_s
    when '200'
      [:success, 'Accepted']
    when '400'
      case status['description']
      when 'Invalid Mobile Number'
        [:message_error, 'Invalid Mobile Number']
      else
        [:temporal_error, 'Bad Request']
      end
    when '401'
      [:system_error, 'Unauthorized']
    when '403'
      [:system_error, 'Method Not Allowed']
    when '404'
      [:system_error, 'URI Not Found']
    when '500'
      [:system_error, 'General System Error']
    else
      [:system_error, "Unknown error code: #{status['status']} - #{status['message']}"]
    end

  end

end
