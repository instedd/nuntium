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

# StatusCode values:
# 100: Processed
# 101: Sent
# 102: Queued
# 401: RiskHold
# 402: InvalidSenderId
# 403: InvalidPhoneNumber
# 404: UnsupportedNumberType
# 405: InsufficientBalance
# 406: UserInBlackList
# 407: CouldNotRoute
# 500: InternalServerError
# 501: GatewayError
# 502: RejectedByGateway

class SendAfricasTalkingMessageJob < SendMessageJob
  def managed_perform
    gateway = ::AfricasTalkingGateway.new(@config[:username], @config[:api_key], @config[:use_sandbox] == "1" ? "sandbox" : nil)

    begin
      destination_number = @msg.to.sub(/^sms:\/\//, '+')

      reports = gateway.sendMessage(destination_number, @msg.body, @config[:shortcode])

      report = reports[0]
      success_delivery(report)
    rescue AfricasTalkingGatewayException => ex
      Rails.logger.error "Exception - API returned status #{ex.statusCode} - #{ex.message}"
      case ex.statusCode
      when 401, 403, 404, 406, 502
        raise MessageException.new(Exception.new(ex.message))
        false
      when 405, 407, 500, 501
        raise "Temporal problem #{ex.message}"
        false
      when 402
        raise PermanentException.new(Exception.new(ex.message))
        false
      else
        # We are probably using sandbox, but this is also useful in case we are in production mode and the API doesn't send the statusCode
        if (ex.message != "Success")
          raise MessageException.new(Exception.new(ex.message))
          false
        else
          success_delivery(report)
        end
      end
    end
  end

  def success_delivery report
    @msg.channel_relative_id = report.messageId if report.messageId
    @msg.custom_attributes["africas_talking_status"] = report.status if report.status
    @msg.custom_attributes["africas_talking_credits_cost"] = report.cost if report.cost
    true
  end
end
