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

class SendGeopollMessageJob < SendMessageJob
  def managed_perform
    query_parameters = {
      'MessageText' => @msg.body,
      'TargetAddress' => @msg.to.without_protocol,
      'Identifier' => @msg.guid,
      'AdditionalFields' => {},
      'IsOptin' => true,
      'IsBulk' => true,
      'DateSent' => DateTime.now.strftime("%FT%T.%L%RZ")
    }

    replied_at =
        if @msg.custom_attributes['reply_sequence'] == '0' && reply_to = @msg.custom_attributes['reply_to']
          @channel.at_messages.find_by_guid(reply_to)
        end

    if replied_at
      @account.logger.info(channel_id: @channel.id, ao_message_id: @msg.id,
                           message: "Sending to GeoPoll as REPLY of AT message with id #{replied_at.id}")

      query_parameters.merge!({
                                  message_type: 'REPLY',
                                  request_id: replied_at.channel_relative_id,
                                  request_cost: 'FREE'
                              })
    end

    begin
      response = RestClient.post(Geopoll::SMS_SEND_URL, query_parameters.to_json, {content_type: :json, accept: :json, "Authorization" => @config[:auth_token]})
      json_response = JSON.parse response

      @msg.channel_relative_id = json_response["OutgoingMessageIds"].first

      case json_response["Status"]["Code"]
      when 0
        @msg.status = 'delayed' # FIXME: state gets overriden after `managed_perform`. It may also be OK to leave the message as delivered.
        return true
      else
        raise Geopoll.error_messsage(json_response)
      end

    rescue => e
      # FIXME: check errors
      raise e
    #   unless e.response
    #     raise e
    #   end

    #   result = JSON.parse(e.response.body)
    #   status, status_description = Geopoll.send_status(result)
    #   description = result["description"] || result["message"] || status_description

    #   case status
    #   when :system_error
    #     raise PermanentException.new(Exception.new(description))
    #   when :message_error
    #     raise MessageException.new(Exception.new(description))
    #   else
    #     raise description
    #   end
    end
  end
end
