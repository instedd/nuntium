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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class ItexmoController < ApplicationController
  skip_filter :check_login

  # POST /:account_name/:channel_name/:incoming_password/itexmo/incoming
  def incoming
    account = Account.find_by_id_or_name(params[:account_name])
    channel = account.itexmo_channels.find_by_name(params[:channel_name])
    if channel.configuration[:incoming_password].to_s != params[:incoming_password]
      return render text: "Error", status: :unauthorized
    end

    from = params["msisdn"]
    to = params["from"] # Yes. The `from` parameter actually means the destination of the message (ie, the server's phone number)

    msg = AtMessage.new
    msg.from = "sms://#{from}"
    msg.to = "sms://#{to}"
    msg.body = params["message"]
    msg.channel_relative_id = params["transid"]

    account.route_at msg, channel

    render text: "Accepted"
  end
end
