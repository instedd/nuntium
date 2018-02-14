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

class IpopController < ApplicationController
  skip_before_action :check_login
  before_action :authenticate

  def index
    msg = AtMessage.new
    msg.from = params[:hp].with_protocol 'sms'
    msg.to = (@channel.address || '').with_protocol 'sms'
    msg.body = params[:txt]
    msg.timestamp = DateTime.strptime(params[:ts][0 .. -4], '%Y%m%d%H%M%S').to_time
    msg.channel_relative_id = params[:ts]

    @account.route_at msg, @channel

    render :text => 'OK'
  end

  def ack
    status = params[:st].to_i
    status_message = IpopChannel::StatusCodes[status]

    msg = AoMessage.find_by_channel_id_and_channel_relative_id @channel.id, "#{params[:hp]}-#{params[:ts]}"
    return render :text => 'NOK 1' unless msg
    msg.state = (status == 4 || status == 5) ? 'confirmed' : 'failed'
    msg.save!

    log_message = "Recieved status notification with status #{status} (#{status_message})"

    if status == 6
      detailed_status = params[:dst].to_i
      detailed_status_message = IpopChannel::DetailedStatusCodes[detailed_status]
      log_message << ". Detailed status code #{detailed_status}: #{detailed_status_message}"

      # Insufficient credit
      if detailed_status == 13
        @channel.alert detailed_status_message
      end

      # I-POP bug
      if detailed_status == 15
        @channel.alert "Something went wrong. Please notify I-POP support."
      end
    end

    @account.logger.info :channel_id => @channel.id, :ao_message_id => msg.id,
      :message => log_message

    render :text => 'OK'
  end

  private

  def authenticate
    @account = Account.find_by_id_or_name params[:account_id]
    return head :unauthorized unless @account

    @channel = @account.channels.find_by_name params[:channel_name]
    return head :unauthorized unless @channel && @channel.kind == 'ipop'
  end
end
