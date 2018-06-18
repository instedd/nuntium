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

      report = reports[0]

      if (report.status != "Success")
        raise MessageException.new(Exception.new(reports[0].status))
        false
      else
        @msg.channel_relative_id = report.messageId if report.messageId
        @msg.custom_attributes["africas_taliking_status"] = report.status if report.status
        @msg.custom_attributes["africas_taliking_credits_cost"] = report.cost if report.cost
        true
      end
    rescue AfricasTalkingGatewayException => ex
      puts 'Encountered an error: ' + ex.message
      false
    end
  end
end
