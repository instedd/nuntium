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

class SendNexmoMessageJob < SendMessageJob
  def managed_perform
    response = RestClient.get "https://rest.nexmo.com/sms/json?#{query_parameters.to_query}",
      headers: {"Content-Type" => "application/json"}
    result = JSON.parse(response.body)
    messages = result["messages"]
    statuses = messages.map { |msg| msg["status"] }
    remaining_balance = messages.map { |msg| msg["remaining-balance"] }
    message_price = messages.map { |msg| msg["message-price"] }
    network = messages.map { |msg| msg["network"] }
    uniq_statuses = statuses.uniq

    @msg.custom_attributes["nexmo_status"] = statuses
    @msg.custom_attributes["nexmo_remaining_balance"] = remaining_balance
    @msg.custom_attributes["nexmo_message_price"] = message_price
    @msg.custom_attributes["nexmo_network"] = network

    # Means all messages were sent OK
    if uniq_statuses == ["0"]
      ids = messages.map { |msg| msg["message-id"] }

      # Only keep the first ID so at least we can track that one
      @msg.channel_relative_id = ids.first
    else
      error = messages.map { |msg| msg["error-text"] }.compact.join(", ")
      raise MessageException.new(Exception.new(error))
    end
  end

  def query_parameters
    {
      :from => @config[:from],
      :to => @msg.to.without_protocol,
      :api_key => @config[:api_key],
      :api_secret => @config[:api_secret],
      :type => 'text',
      :text => @msg.body,
      :"status-report-req" => '1',
      :"client-ref" => @msg.guid,
      :"callback" => "#{Settings.host_name}/#{@msg.account_id}/#{@channel.id}/nexmo/#{@channel.callback_token}/ack",
    }
  end
end
