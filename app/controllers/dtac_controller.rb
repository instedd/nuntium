require 'iconv'

class DtacController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate

  def index
    converter = Iconv.new('UTF-8','TIS-620')
    text = converter.iconv(params[:CONTENT])

    msg = AtMessage.new
    msg.from = "sms://#{params[:MSISDN]}"
    msg.to = "sms://#{params[:SMSCODE]}"
    msg.body = text
    msg.channel_relative_id = params[:ID]
    msg.timestamp = Time.now.utc

    @account.route_at msg, nil

    head :ok
  end

  def authenticate
    @account = Account.find_by_id_or_name(params[:account_id])
    return !@account.nil?
  end

end
