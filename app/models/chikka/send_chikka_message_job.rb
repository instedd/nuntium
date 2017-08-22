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
    query_parameters = {
      :message_type => 'SEND',
      :mobile_number => @msg.to.without_protocol,
      :shortcode => @config[:shortcode],
      :message_id => @msg.guid.delete('-'),
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
      @msg.channel_relative_id = @msg.guid.delete('-')
      true
    when :temporal_error
      raise ChikkaException.new(Exception.new(description))
    when :message_error
      raise MessageException.new(Exception.new(description))
    else
      raise PermanentException.new(Exception.new(description))
    end
  end
end
