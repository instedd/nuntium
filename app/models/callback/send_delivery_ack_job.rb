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

class SendDeliveryAckJob
  attr_accessor :account_id, :application_id, :message_id, :state, :tries

  def initialize(account_id, application_id, message_id, state, tries = 0)
    @account_id = account_id
    @application_id = application_id
    @message_id = message_id
    @state = state
    @tries = tries
  end

  def perform
    @account = Account.find_by_id @account_id
    @app = @account.applications.find_by_id @application_id
    @msg = AoMessage.get_message @message_id
    @chan = @account.channels.find_by_id @msg.channel_id

    return unless @app and @chan and @app.delivery_ack_method != 'none'

    data = {:guid => @msg.guid, :channel => @chan.name, :state => @state}.merge(@msg.custom_attributes)
    delivery_url = URI.parse(@app.delivery_ack_url)
    if @app.delivery_ack_method == 'get' && (query = delivery_url.query)
      uri_query = Rack::Utils.parse_nested_query(query)
      data.merge!(uri_query)
      delivery_url.query = nil
    end

    delivery_url = delivery_url.to_s

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}
    if @app.delivery_ack_user.present?
      options[:user] = @app.delivery_ack_user
      options[:password] = @app.delivery_ack_password
    end

    begin
      res = RestClient::Resource.new delivery_url, options
      res = @app.delivery_ack_method == 'get' ? res["?#{data.to_query}"].get : res.post(data)
      res = res.net_http_res

      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          return
        when Net::HTTPUnauthorized
          alert_msg = "Sending HTTP delivery ack received unauthorized: invalid credentials"
          @app.alert alert_msg
          raise alert_msg
        else
          raise "HTTP delivery ack failed: #{res.error!}"
      end
    rescue RestClient::BadRequest
      @app.logger.warning :ao_message_id => @message_id, :message => "Received HTTP Bad Request (404) for delivery ack"
    end
  end

  def reschedule(ex)
    @app.logger.warning :ao_message_id => @message_id, :message => ex.message

    tries = self.tries + 1
    new_job = self.class.new(@account_id, @application_id, @message_id, @state, tries)
    ScheduledJob.create! :job => RepublishApplicationJob.new(@application_id, new_job), :run_at => tries.as_exponential_backoff.minutes.from_now
  end
end
