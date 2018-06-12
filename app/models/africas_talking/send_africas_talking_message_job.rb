# Copyright (C) 2009-2017, InSTEDD
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
require_relative './AfricasTalkingGateway'

class SendAfricasTalkingMessageJob < SendMessageJob
  def managed_perform
    gateway = ::AfricasTalkingGateway.new(@config[:username], @config[:api_key], @config[:use_sandbox] == "1" ? "sandbox" : nil)

    begin
      destination_number = @msg.to.sub(/^sms:\/\//, '+')
      reports = gateway.sendMessage(destination_number, @msg.body, @config[:shortcode])
      true
    rescue AfricasTalkingGatewayException => ex
      puts 'Encountered an error: ' + ex.message
      false
    end

    # query_parameters = {
    #   :message_type => 'SEND',
    #   :mobile_number => @msg.to.without_protocol,
    #   :shortcode => @config[:shortcode],
    #   :message_id => @msg.guid.delete('-'),
    #   :message => @msg.body,
    #   :client_id => @config[:client_id],
    #   :secret_key => @config[:secret_key]
    # }

    # replied_at =
    #   if @msg.custom_attributes['reply_sequence'] == '0' && reply_to = @msg.custom_attributes['reply_to']
    #     @channel.at_messages.find_by_guid(reply_to)
    #   end

    # if replied_at
    #   @account.logger.info(channel_id: @channel.id, ao_message_id: @msg.id,
    #     message: "Sending to Chikka as REPLY of AT message with id #{replied_at.id}")

    #   query_parameters.merge!({
    #     message_type: 'REPLY',
    #     request_id: replied_at.channel_relative_id,
    #     request_cost: 'FREE'
    #   })
    # end

    # begin
    #   response = RestClient.post("https://post.chikka.com/smsapi/request", query_parameters, headers: {"Content-Type" => "application/json"})
    #   @msg.channel_relative_id = @msg.guid.delete('-')
    #   true

    # rescue RestClient::ExceptionWithResponse => e
    #   unless e.response
    #     raise e
    #   end

    #   result = JSON.parse(e.response.body)
    #   status, status_description = Chikka.send_status(result)
    #   description = result["description"] || result["message"] || status_description

    #   case status
    #   when :system_error
    #     raise PermanentException.new(Exception.new(description))
    #   when :message_error
    #     raise MessageException.new(Exception.new(description))
    #   else
    #     raise description
    #   end
    # end
  end
end
