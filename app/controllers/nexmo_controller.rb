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

class NexmoController < ApplicationController
  skip_filter :check_login

  # GET /nexmo/:account_id/:channel_id/incoming
  def incoming
    account = Account.find_by_id_or_name(params[:account_id])
    channel = account.nexmo_channels.find(params[:channel_id])

    if channel.callback_token != params[:callback_token]
      return head :unauthorized
    end

    msisdn = params[:msisdn]
    to = params[:to]
    text = params[:text]
    message_id = params[:messageId]

    concat = (params[:concat] || "").downcase == "true"

    # Messages can come in pieces, if concat is true
    if concat
      concat_ref = params[:"concat-ref"]
      concat_total = params[:"concat-total"].to_i
      concat_part = params[:"concat-part"].to_i

      msg = channel.at_messages.find_by_channel_relative_id_and_state(concat_ref, "pending") || AtMessage.new
      msg.account ||= account
      msg.from ||= "sms://#{msisdn}"
      msg.to ||= "sms://#{to}"
      msg.channel_relative_id ||= concat_ref
      msg.channel ||= channel

      # Store parts in a custom attribute
      msg.custom_attributes["nexmo_parts"] ||= Array.new(concat_total, nil)
      msg.custom_attributes["nexmo_parts"][concat_part - 1] = text

      # Once all parts are received, route the message
      if msg.custom_attributes["nexmo_parts"].all?
        msg.body = msg.custom_attributes["nexmo_parts"].join
        msg.custom_attributes["nexmo_parts"] = nil
        msg.channel_relative_id = message_id
        account.route_at msg, channel
      else
        msg.save!
      end
    else
      msg = AtMessage.new
      msg.from = "sms://#{msisdn}"
      msg.to = "sms://#{to}"
      msg.body = text
      msg.channel_relative_id = message_id
      account.route_at msg, channel
    end

    head :ok
  end

  # GET /nexmo/:account_id/:channel_id/ack
  def ack
    account = Account.find_by_id_or_name(params[:account_id])
    channel = account.nexmo_channels.find(params[:channel_id])

    ao = channel.ao_messages.find_by_channel_relative_id(params[:messageId])
    return head :ok unless ao

    status = params[:status]
    status = status.downcase if status

    err_code = params[:"err-code"]
    price = params[:price]

    account.logger.info :channel_id => channel.id, :ao_message_id => ao.id,
      :message => "Recieved status notification with status #{status.inspect} and err-code #{err_code} (price #{price})"

    ao.custom_attributes["nexmo_delivery_status"] = status if status
    ao.custom_attributes["nexmo_delivery_err_code"] = err_code if err_code && status != "accepted"
    ao.custom_attributes["nexmo_delivery_price"] = price if price

    case status
    when "buffered"
      # Don't change state yet...
    when "accepted"
      ao.state = 'delivered'
    when "delivered"
      ao.state = 'confirmed'
    else
      ao.state = 'failed'
    end

    ao.save!

    head :ok
  end
end
