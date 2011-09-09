class TwilioController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate, :only => [:index, :ack]

  def index
    msg = AtMessage.new
    msg.from = "sms://1#{params[:From]}"
    msg.to = "sms://1#{params[:To]}"
    msg.body = params[:Body]
    msg.channel_relative_id = params[:SmsSid]
    @account.route_at msg, @channel

    head :ok
  end

  def ack
    msg = AoMessage.find_by_channel_id_and_channel_relative_id @channel.id, params[:SmsSid]
    msg.state = case params[:SmsStatus]
                when 'sent' then 'confirmed'
                when 'failed' then 'failed'
                end
    msg.save!

    head :ok
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if @account
        @channel = @account.twilio_channels.where(:name => username).select do |c|
          c.configuration[:account_sid] == params[:AccountSid] &&
          c.configuration[:incoming_password] == password
        end.first
      else
        false
      end
    end
  end
end
