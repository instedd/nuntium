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

class TwilioController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate, :only => [:index, :ack]

  def index
    msg = AtMessage.new
    msg.from = "sms://#{params[:From]}"
    msg.to = "sms://#{params[:To]}"
    msg.body = params[:Body]
    msg.channel_relative_id = params[:SmsSid]
    @account.route_at msg, @channel

    head :ok
  end

  def ack
    msg = AoMessage.find_by_channel_id_and_channel_relative_id @channel.id, params[:SmsSid]
    msg.state = case params[:SmsStatus]
                when 'sent' then 'confirmed'
                when 'failed' then 'failed'
                end
    msg.save!

    head :ok
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if @account
        @channel = @account.channels.select do |c|
          c.kind == 'twilio' &&
          c.configuration[:account_sid] == params[:AccountSid] &&
          c.name == username &&
          c.configuration[:incoming_password] == password
        end.first
      else
        false
      end
    end
  end
end
