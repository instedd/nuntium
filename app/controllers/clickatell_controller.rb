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

require 'iconv'

class ClickatellController < ApplicationController
  before_filter :authenticate, :only => [:index, :ack]
  skip_filter :check_login, :except => [:view_credit]

  @@clickatell_timezone = ActiveSupport::TimeZone.new 2.hours

  # GET /clickatell/:account_id/incoming
  def index
    if params[:udh].present?
      udh = Udh.new(params[:udh].hex_to_bytes)
      return index_multipart_message udh if udh[0]
    end

    index_single_message
  end

  # GET /clickatell/:account_id/ack
  def ack
    # This is the case when clickatell verifies this URL
    return head :ok unless params[:apiMsgId]

    msg = AoMessage.find_by_channel_id_and_channel_relative_id @channel.id, params[:apiMsgId]
    return head :ok unless msg

    case params[:status].to_i
    when 4
      msg.state = 'confirmed'
    when 5, 6, 7, 12
      msg.state = 'failed'
    end

    unless msg.custom_attributes[:cost]
      cost_per_credit = (@channel.cost_per_credit || '1').to_f
      msg.custom_attributes[:cost] = (cost_per_credit * params[:charge].to_f).round 2
    end
    msg.save!

    status_message = ClickatellChannel::CLICKATELL_STATUSES[params[:status]][0]
    @account.logger.info :channel_id => @channel.id, :ao_message_id => msg.id,
      :message => "Recieved status notification with status #{params[:status]} (#{status_message}) and credit #{params[:charge]} (cost #{msg.custom_attributes[:cost]})"

    head :ok
  end

  def view_credit
    id = params[:id]
    @channel = account.channels.find_by_id id
    return redirect_to_home unless @channel && @channel.kind == 'clickatell'

    render :text => @channel.get_credit
  end

  private

  def index_single_message
    create_message params[:text]
    head :ok
  end

  def index_multipart_message(udh)
    # Search other received parts
    parts = ClickatellMessagePart.where(:originating_isdn => params[:from], :reference_number => udh[0][:reference_number])
    all_parts = parts.all

    # If all other parts are there
    if all_parts.length == udh[0][:part_count] - 1
      # Add this new part, sort and get text
      all_parts.push ClickatellMessagePart.new(:part_number => udh[0][:part_number], :text => params[:text])
      all_parts.sort! { |x,y| x.part_number <=> y.part_number }
      text = all_parts.map(&:text).join

      # Create message from the resulting text
      create_message text

      # Delete stored information
      parts.delete_all
    else
      # Just save the part
      ClickatellMessagePart.create(
        :originating_isdn => params[:from],
        :reference_number => udh[0][:reference_number],
        :part_count => udh[0][:part_count],
        :part_number => udh[0][:part_number],
        :timestamp => get_timestamp,
        :text => params[:text]
        )
    end

    head :ok
  end

  def create_message(text)
    msg = AtMessage.new
    msg.from = "sms://#{params[:from]}"
    msg.to = "sms://#{params[:to]}"
    msg.body = Iconv.new('UTF-8', params[:charset]).iconv(text)
    msg.channel_relative_id = params[:moMsgId]
    msg.timestamp = get_timestamp
    @account.route_at msg, @channel
  end

  def get_timestamp
    @@clickatell_timezone.parse(params[:timestamp]).utc rescue Time.now.utc
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if !@account.nil?
        @channel = @account.clickatell_channels.where(:name => username).all.select{|x| x.incoming_password == password}.first
      else
        false
      end
    end
  end
end
