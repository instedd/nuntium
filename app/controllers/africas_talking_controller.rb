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

class AfricasTalkingController < ApplicationController
  skip_filter :check_login

  # POST /:account_name/:channel_name/:secret_token/africas_talking/incoming
  def incoming
    account = Account.find_by_id_or_name(params[:account_name])
    channel = account.africas_talking_channels.find_by_name(params[:channel_name])

    if channel.shortcode != params[:to] || channel.secret_token != params[:secret_token]
      return render text: "Error", status: :unauthorized
    end

    msg = AtMessage.new
    msg.from = "sms://#{params[:from]}"
    msg.to   = "sms://#{params[:to]}"
    msg.body = params[:text]
    msg.channel_relative_id = params[:id]
    msg.custom_attributes["africas_talking_link_id"] = params[:linkId]
    account.route_at msg, channel

    render text: "Accepted"
  end

  # POST /:account_name/:channel_name/:secret_token/africas_talking/delivery_reports
  def delivery_reports
    account = Account.find_by_id_or_name(params[:account_name])
    channel = account.africas_talking_channels.find_by_name(params[:channel_name])

    if channel && channel.secret_token != params[:secret_token]
      return render text: "Error", status: :unauthorized
    end

    ao = channel.ao_messages.find_by_channel_relative_id(params[:id])
    unless ao
      return render text: "Error", status: :not_found
    end

    status = params[:status]
    retry_count = params[:retryCount]

    case status
    when "Success"
      ao.state = "confirmed"
    when "Failed", "Rejected"
      ao.state = "failed"
      ao.custom_attributes["africas_talking_failure_reason"] = params[:failureReason] if params[:failureReason]
    else
      ao.state = "failed"
    end

    account.logger.info :channel_id => channel.id, :ao_message_id => ao.id,
      :message => "Recieved delivery notification with status #{status.inspect} (retried #{retry_count} times)"

    ao.custom_attributes["africas_talking_retries"] = retry_count if retry_count
    ao.save!

    render text: "Accepted"
  end
end
