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

class NexmoChannel < Channel
  include GenericChannel

  configuration_accessor :from, :api_key, :api_secret, :callback_token

  validates_presence_of :from, :api_key, :api_secret, :callback_token

  handle_password_change :api_secret

  before_validation :generate_callback_token, :on => :create

  before_save :configure_nexmo_incoming_callback

  def self.default_protocol
    'sms'
  end

  def more_info(ao_msg)
    status = ao_msg.custom_attributes["nexmo_status"] || []
    remaining_balance = ao_msg.custom_attributes["nexmo_remaining_balance"] || []
    message_price = ao_msg.custom_attributes["nexmo_message_price"] || []
    network = ao_msg.custom_attributes["nexmo_network"] || []

    ret = {}
    status.each_with_index do |code, index|
      if status.length == 1
        msg_number = ""
      else
        msg_number = " #{index + 1}"
      end

      if code != "0"
        text, meaning = Nexmo::SEND_STATUS[code]
        if text && meaning
          ret["Nexmo status code#{msg_number}"] = code
          ret["Nexmo error text#{msg_number}"] = text
          ret["Nexmo error meaning#{msg_number}"] = meaning
        end
      end

      balance = remaining_balance[index]
      if balance
        ret["Nexmo remaining balance#{msg_number}"] = balance
      end

      price = message_price[index]
      if price
        ret["Nexmo message price#{msg_number}"] = price
      end

      network_value = network[index]
      if network_value
        ret["Nexmo network#{msg_number}"] = network_value
      end
    end
    ret
  end

  def incoming_callback_url
    "#{Settings.host_name}/#{account_id}/#{id}/nexmo/#{callback_token}/incoming"
  end

  def ui_save_notice
    if @configured_nexmo_incoming_callback
      nil
    else
      "Channel was saved, but the incoming URL couldn't be configured.<br/>Please configure it <a href=\"https://dashboard.nexmo.com/settings\">here</a> to<br/>#{incoming_callback_url}".html_safe
    end
  end

  private

  def generate_callback_token
    self.callback_token = Guid.new.to_s
  end

  def configure_nexmo_incoming_callback
    query = {
      api_key: api_key,
      api_secret: api_secret,
      moCallBackUrl: incoming_callback_url,
    }

    url = "https://rest.nexmo.com/account/settings?#{query.to_query}"
    headers = {"Content-Type" => "application/x-www-form-urlencoded"}
    begin
      RestClient.post(url, headers: headers)
      @configured_nexmo_incoming_callback = true
    rescue => ex
      @configured_nexmo_incoming_callback = false
    end

    true
  end
end
