class TwilioController < AccountAuthenticatedController
  before_filter :authenticate, :only => [:index, :ack]
  
  def index    
    msg = ATMessage.new
    msg.from = "sms://#{params[:From]}"
    msg.to = "sms://#{params[:To]}"
    msg.body = params[:Body]
    msg.channel_relative_id = params[:SmsSid]
    @account.route_at msg, @channel
    
    head :ok
  end
  
  def ack
    msg = AOMessage.find_by_channel_id_and_channel_relative_id @channel.id, params[:SmsSid]
    
    case params[:SmsStatus]
    when 'sent'
      msg.state = 'confirmed'
    when 'failed'
      msg.state = 'failed'
    end
    
    msg.save!
    
    head :ok
  end
  
  private
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if !@account.nil?
        @channel = @account.channels.select do |c|
          c.kind == 'twilio' && 
          c.configuration[:account_sid] == params[:AccountSid] &&
          c.name == username &&
          c.configuration[:incoming_password] == password
        end.first
      else
        false
      end
    end
  end
end