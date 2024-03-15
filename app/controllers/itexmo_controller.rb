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
    unless passwords_match? params[:incoming_password], channel.configuration[:incoming_password]
      return render text: "Error", status: :unauthorized
    end

    from = params["originator"]
    to = params["gateway"]

    unknown_params = params.except(
      'originator', 'gateway', 'message', 'timestamp', # iTexmo API specification
      'account_name', 'channel_name', 'incoming_password', 'controller', 'action' # Rails-generated parameters
    )

    msg = AtMessage.new
    msg.from = "sms://#{from}"
    msg.to = "sms://#{to}"
    msg.body = params["message"]

    account.route_at msg, channel

    channel.logger.warning :channel_id => channel.id, :at_message_id => msg.id, :message => "Received unknown parameters for AT #{msg.id}: #{unknown_params.to_json}" unless unknown_params.empty?

    render text: "Accepted"
  end

  # POST /:account_name/:channel_name/:incoming_password/itexmo/:ao_message_id/delivery
  def delivery
    account = Account.find_by_id_or_name(params[:account_name])
    channel = account.itexmo_channels.find_by_name(params[:channel_name])
    unless passwords_match? params[:incoming_password], channel.configuration[:incoming_password]
      return render text: "Error", status: :unauthorized
    end
    ao_message = channel.ao_messages.find_by_id(params[:ao_message_id])

    case params['Status'].try :downcase
    when 'accepted'
      ao_message.state = 'delivered' if ['queued', 'pending'].include?(ao_message.state)
    when 'delivered'
      ao_message.state = 'confirmed'
    else
      channel.logger.warning :channel_id => channel.id, :ao_message_id => ao_message.id, :message => "Received unknown-status delivery notification for AO #{ao_message.id}: #{params.to_json}"
    end

    ao_message.custom_attributes["itexmo_network_submit_time"] = params['NetworkSubmitTime'] if params['NetworkSubmitTime']
    ao_message.custom_attributes["itexmo_client_submit_time"] = params['ClientSubmitTime'] if params['ClientSubmitTime']
    ao_message.custom_attributes["itexmo_done_time"] = params['DoneTime'] if params['DoneTime']
    ao_message.channel_relative_id ||= params['LongID']

    ao_message.save!

    unknown_params = params.except(
      'LongID', 'Recipient', 'Status', 'NetworkSubmitTime', 'ClientSubmitTime', 'DoneTime', # iTexmo API specification
      'account_name', 'channel_name', 'incoming_password', 'ao_message_id', 'controller', 'action' # Rails-generated parameters
    )
    channel.logger.warning :channel_id => channel.id, :at_message_id => msg.id, :message => "Received unknown parameters for AO #{msg.id} Delivery ACK: #{unknown_params.to_json}" unless unknown_params.empty?

    render text: "OK"
  end

  private

  def passwords_match?(user_input, channel_password)
    user_input_hash = Digest::SHA512.digest user_input.to_s
    channel_password_hash = Digest::SHA512.digest channel_password.to_s
    ActiveSupport::SecurityUtils.secure_compare user_input_hash, channel_password_hash
  end
end
