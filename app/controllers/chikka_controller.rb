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

class ChikkaController < ApplicationController
  skip_filter :check_login


  # POST /:account_id/:channel_id/chikka/incoming

  def incoming
    Rails.logger.debug("-------------==================== PARAMS  ====================-------------")
    Rails.logger.debug(params)
    puts "-------------==================== PARAMS 2  ====================-------------"
    puts params
    account = Account.find_by_id_or_name(params[:account_id])
    channel = account.chikka_channels.find(params[:channel_id])
    Rails.logger.debug("-------------==================== ACCOUNT & CHANNEL ====================-------------")
    Rails.logger.debug(account)
    Rails.logger.debug(channel)

    if channel.shortcode != params[:shortcode]
      return head :unauthorized
    end

    msg = AtMessage.new
    msg.from = params[:mobile_number]
    msg.to   = params[:shortcode]
    msg.body = params[:message]
    msg.custom_attributes["chikka_request_id"] = params[:request_id]
    account.route_at msg, channel

    head :ok
  end

  # {"timestamp"=>"1502239412.36", "request_id"=>"5048303030303053554E303030303239323930303031303030303030303030303030303036333933323835393531363330303030303930383137303034333236", "mobile_number"=>"639328595163", "message"=>"Hi again", "shortcode"=>"29290514844", "message_type"=>"incoming", "account_id"=>"1", "channel_id"=>"1"}


  # GET /:account_id/:channel_id/chikka/ack
  def ack
    account = Account.find_by_id_or_name(params[:account_id])
    channel = account.chikka_channels.find(params[:channel_id])

    ao = channel.ao_messages.find_by_channel_relative_id(params[:message_id])
    return head :ok unless ao

    status = params[:status]
    status = status.downcase if status

    rb_cost = params[:rb_cost]
    credits_cost= params[:credits_cost]

    account.logger.info :channel_id => channel.id, :ao_message_id => ao.id,
      :message => "Recieved status notification with status #{status.inspect} (rb_cost: #{rb_cost}, credits_cost: #{credits_cost})"

    ao.custom_attributes["chikka_delivery_status"] = status if status
    ao.custom_attributes["chikka_delivery_rb_cost"] = rb_cost if rb_cost
    ao.custom_attributes["chikka_delivery_credits_cost"] = credits_cost if credits_cost

    case status
      when "sent"
        ao.state = 'confirmed'
      else
        ao.state = 'failed'
    end

    ao.save!

    head :ok
  end
end
