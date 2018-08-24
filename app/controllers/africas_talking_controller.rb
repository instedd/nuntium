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

    if channel.secret_token != params[:secret_token]
      return render text: "Error", status: :unauthorized
    end

    msg = AtMessage.new
    msg.from = "sms://#{params[:from]}"
    msg.to   = "sms://#{params[:to].tr('+', '')}"
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
    # when "Submitted", "Buffered"
    #   ao.state = "queued"
    # else
    #   ao.state = "failed"
    end

    account.logger.info :channel_id => channel.id, :ao_message_id => ao.id,
      :message => "Recieved delivery notification with status #{status.inspect} (retried #{retry_count} times)"

    if params[:networkCode]
      ao.custom_attributes["africas_talking_network_name"] = translate_network_code(params[:networkCode])
      ao.custom_attributes["africas_talking_network_code"] = params[:networkCode]
    end
    ao.custom_attributes["africas_talking_retries"] = retry_count if retry_count
    ao.save!

    render text: "Accepted"
  end

  def translate_network_code network_code
    case network_code.to_i
      when 62120
        "Airtel Nigeria"
      when 62130
        "MTN Nigeria"
      when 62150
        "Glo Nigeria"
      when 62160
        "Etisalat Nigeria"
      when 63510
        "MTN Rwanda"
      when 63513
        "Tigo Rwanda"
      when 63514
        "Airtel Rwanda"
      when 63902
        "Safaricom"
      when 63903
        "Airtel Kenya"
      when 63907
        "Orange Kenya"
      when 63999
        "Equitel Kenya"
      when 64002
        "Tigo Tanzania"
      when 64003
        "Zantel Tanzania"
      when 64004
        "Vodacom Tanzania"
      when 64005
        "Airtel Tanzania"
      when 64007
        "TTCL Tanzania"
      when 64009
        "Halotel Tanzania"
      when 64101
        "Airtel Uganda"
      when 64110
        "MTN Uganda"
      when 64111
        "UTL Uganda"
      when 64114
        "Africell Uganda"
      when 65001
        "TNM Malawi"
      when 65010
        "Airtel Malawi"
    end
  end

end
