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

class SendChikkaMessageJob < SendMessageJob
  def managed_perform
    # TODO - check if @msg.guid works here
    message_id = SecureRandom.uuid.delete('-')

    query_parameters = {
      :message_type => 'SEND',
      :mobile_number => @msg.to.without_protocol,
      :shortcode => @config[:shortcode],
      :message_id => message_id,
      :message => @msg.body,
      :client_id => @config[:client_id],
      :secret_key => @config[:secret_key]
    }
    begin
      response = RestClient.post("https://post.chikka.com/smsapi/request", query_parameters, headers: {"Content-Type" => "application/json"})
    rescue RestClient::BadRequest => e
      response = e.response
    rescue Exception => e
      response = e.response
    end
    result = JSON.parse(response.body)


    status, description = Chikka.send_status(result)


    case status
    when :success
      @msg.channel_relative_id = message_id
      true
    when :message_error
      raise MessageException.new(Exception.new(description))
    else # FIXME: which option should be the default?
      raise PermanentException.new(Exception.new(description))
    end
    # messages = result["messages"]
    # statuses = messages.map { |msg| msg["status"] }
    # remaining_balance = messages.map { |msg| msg["remaining-balance"] }
    # message_price = messages.map { |msg| msg["message-price"] }
    # network = messages.map { |msg| msg["network"] }
    # uniq_statuses = statuses.uniq
    #
    # @msg.custom_attributes["nexmo_status"] = statuses
    # @msg.custom_attributes["nexmo_remaining_balance"] = remaining_balance
    # @msg.custom_attributes["nexmo_message_price"] = message_price
    # @msg.custom_attributes["nexmo_network"] = network
    #
    # # Means all messages were sent OK
    # if uniq_statuses == ["0"]
    #   ids = messages.map { |msg| msg["message-id"] }
    #
    #   # Only keep the first ID so at least we can track that one
    #   @msg.channel_relative_id = ids.first
    # else
    #   error = messages.map { |msg| msg["error-text"] }.compact.join(", ")
    #   raise MessageException.new(Exception.new(error))
    # end
  end
end
