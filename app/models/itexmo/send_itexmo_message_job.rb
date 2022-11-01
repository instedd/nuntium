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

class SendItexmoMessageJob < SendMessageJob
  def managed_perform
    query_parameters = Itexmo.send_message_parameters({
      number: @msg.to.without_protocol,
      body: @msg.body,
      email: @config[:email],
      api_code: @config[:api_code],
      api_password: @config[:api_password],
      delivery_report_url: NamedRoutes.itexmo_delivery_url(@account.name, @channel.name, @config[:incoming_password], @msg.id)
    })

    begin
      raw_response = RestClient::Request.execute(:method => :post, :url => Itexmo::SMS_SEND_URL, :payload => query_parameters, :timeout => 30)

      response = JSON.parse raw_response

      if response['Error']
        # TODO: improve error handling
        raise MessageException.new(Exception.new("Error sending Itexmo message - #{response}"))
      end

      @msg.channel_relative_id = response['ReferenceId'] if response['ReferenceId']
      @msg.custom_attributes["itexmo_total_credit_used"] = response['TotalCreditUsed'] if response['TotalCreditUsed']
      @msg.custom_attributes["itexmo_delivery_report_status"] = response['DeliveryReportStatus'] if response['DeliveryReportStatus']
      true
    rescue => e
      # FIXME: check errors
      raise e
    end
  end
end
