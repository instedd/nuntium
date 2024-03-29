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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class Itexmo
  # endpoint shared internally by iTexmo
  SMS_SEND_URL = 'https://api.itexmo.com/api/broadcast/access-code'

  def self.send_message_parameters(params)
    {
      "Email" => params[:email], # Email of active ITEXMO account (Required, String, Email Format)
      "Password" => params[:api_password], # Password of active ITEXMO account (Required, String)
      "Recipients" => [ params[:number] ], # Recipient/s number (maximum: 250) (Required, Array, Unique)
      "Message" => params[:body], # Message Content (Required, String)
      "ApiCode" => params[:api_code], # Active ApiCode purchased unders client's ITEXMO account (Required, String)
      "SenderId" => params[:sender_id], # String
      "DeliveryReportsURL" => params[:delivery_report_url], # The URL in which our system will push data for the delivery report (URL Format)
    }
  end

  def self.parse_send_response(status_code)
    status, details = case status_code
    when "0"
      [:success, 'Accepted']
    when "1"
      [:message_error, 'Invalid number']
    when "2"
      [:message_error, 'Number prefix not supported - contact iTexMo']
    when "3"
      [:system_error, 'Invalid ApiCode']
    when "4"
      [:system_error, 'Maximum messages per day reached. Retry in 12 minutes.']
    when "5"
      [:message_error, 'Maximum allowed characters for message reached']
    when "6"
      [:system_error, 'iTexMo system offline']
    when "7"
      [:system_error, 'Expired ApiCode']
    when "8"
      [:system_error, 'iTexMo error. Retry later.']
    when "9"
      [:system_error, 'Invalid function parameters']
    when "10"
      [:message_error, 'Recipient\'s number is blocked due to flooding, message was ignored.']
    when "11"
      [:message_error, 'Recipient\'s number is blocked temporarily due to hard sending, message was ignored. Retry in an hour.']
    when "12"
      [:message_error, 'Invalid request. You can\'t set message priorities on non corporate apicodes.']
    when "13"
      [:message_error, 'Invalid or not registered Custom Sender ID']
    when "14"
      [:message_error, 'Invalid preferred server number']
    when "15"
      [:system_error, 'IP Filtering enabled - Invalid IP']
    when "16"
      [:system_error, 'Authentication error - contact iTexMo']
    when "17"
      [:system_error, 'Telco error - contact iTexMo']
    when "18"
      [:system_error, 'Message Filtering Enabled - contact iTexMo']
    else
      [:system_error, "API response code not supported by Nuntium: \"#{status_code}\""]
    end

    [status, "#{details} (##{status_code})"]
  end
end
