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

class SendShujaaMessageJob < SendMessageJob
  def managed_perform
    response = RestClient.get "http://sms.shujaa.mobi/sendsms?#{query_parameters.to_query}"
    if response.body =~ /(.+)\:(.+)/
      msg_id = $1
      msg_status_code = $2

      if msg_id.strip == '0'
        msg_status_code = msg_status_code.to_i

        error = ShujaaChannel::SHUJAA_ERRORS[msg_status_code]

        raise response.body if error.nil?
        raise PermanentException.new(Exception.new(error[:description])) if error[:kind] == :fatal
        raise MessageException.new(Exception.new(error[:description])) if error[:kind] == :message
        raise response.body
      else
        @msg.channel_relative_id = msg_id
      end
    else
      raise response.body
    end
  end

  def query_parameters
    destination = @msg.to.without_protocol
    destination = "254#{destination[1 .. -1]}" if destination[0] == '0'

    params = {}
    params[:username] = @channel.username
    params[:password] = @channel.password
    params[:account] = @channel.shujaa_account
    params[:source] = @channel.address
    params[:destination] = destination
    params[:message] = @msg.subject_and_body
    params
  end
end
