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

require 'digest/md5'

class GeopollController < ApplicationController
  skip_filter :check_login

  # POST /:account_name/:channel_name/:secret_token/geopoll/incoming
  def incoming
    account = Account.find_by_id_or_name(params[:account_name])
    channel = account.geopoll_channels.find_by_name(params[:channel_name])
    auth_token = channel.configuration[:auth_token].to_s.split(' ')[1]
    identifier = params[:Identifier]
    signature = Digest::MD5.hexdigest(auth_token + identifier)

    if signature != params[:Signature]
      return render text: "Error", status: :unauthorized
    end

    msg = AtMessage.new
    msg.from = "sms://#{params[:SourceAddress]}"
    msg.to   = "sms://#{channel.configuration[:from]}"
    msg.body = params[:MessageText]
    msg.channel_relative_id = params[:Identifier]
    account.route_at msg, channel

    render text: "Accepted"
  end

end
