require 'test_helper'

class IpopController < ApplicationController
  before_filter :authenticate

  def index
    msg = AOMessage.new
    msg.from = params[:hp].with_protocol 'sms'
    msg.body = params[:txt]
    msg.timestamp = DateTime.strptime(params[:ts][0 .. -4], '%Y%m%d%H%M%S').to_time
    msg.channel_relative_id = params[:ts]

    @account.route_at msg, @chan

    render :text => 'OK'
  end

  def ack
  end

  private

  def authenticate
    @account = Account.find_by_id_or_name params[:account_id]
    return head :unauthorized unless @account

    @chan = @account.find_channel params[:channel_name]
    return head :unauthorized unless @chan && @chan.kind == 'ipop'
  end
end
