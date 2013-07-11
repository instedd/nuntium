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

class ShujaaController < ApplicationController
  skip_filter :check_login

  def index
    account = Account.find_by_id_or_name(params[:account_id]) or return head(:not_found)
    chans = account.shujaa_channels.all
    chan = chans.find { |c| c.callback_guid == params[:callback_guid] } or return head(:not_found)

    [:source, :destination, :message].each do |key|
      return render :text => "Error: missing parameter '#{key}'", :status => :bad_request if params[key].blank?
    end

    msg = AtMessage.new
    msg.account_id = account.id
    msg.channel_id = chan.id
    msg.from = params[:source].with_protocol 'sms'
    msg.to = params[:destination].with_protocol 'sms'
    msg.body = params[:message]
    msg.channel_relative_id = params[:messageId]
    msg.custom_attributes['network'] = params[:network]

    case params[:network]
    when 'airtel'
      msg.carrier = ShujaaChannel::AIRTEL
    when 'orange'
      msg.carrier = ShujaaChannel::ORANGE
    when 'safaricom'
      msg.carrier = ShujaaChannel::SAFARICOM
    when 'yu'
      msg.carrier = ShujaaChannel::YU
    end

    account.route_at msg, chan

    head :ok
  end
end
