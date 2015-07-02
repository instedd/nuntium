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

require 'iconv'

class DtacController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate

  def index
    converter = Iconv.new('UTF-8','TIS-620')
    text = converter.iconv(params[:CONTENT])

    msg = AtMessage.new
    msg.from = "sms://#{params[:MSISDN]}"
    msg.to = "sms://#{params[:SMSCODE]}"
    msg.body = text
    msg.channel_relative_id = params[:ID]
    msg.timestamp = Time.now.utc

    # FIXME: this doesn't look correct; taken from production environment
    channel = @account.channels.select {|x| x.kind == 'dtac'}.first
    @account.route_at msg, channel

    head :ok
  end

  def authenticate
    @account = Account.find_by_id_or_name(params[:account_id])
    return !@account.nil?
  end

end
