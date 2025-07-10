class TwilioClient
  def initialize(account_sid, auth_token)
    @account_sid = account_sid
    @auth_token = auth_token
  end

  def create_sms(params)
    # POST https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json
    endpoint = "https://api.twilio.com/2010-04-01/Accounts/#{@account_sid}/Messages.json"
    message_params = {
      ShortenUrls: false,
      To: params[:to],
      From: params[:from],
      Body: params[:body],
      StatusCallback: params[:status_callback]
    }

    raw_response = RestClient::Request.execute(:method => :post, :url => endpoint, :payload => message_params, :user => @account_sid, :password => @auth_token, :timeout => 30)

    JSON.parse raw_response
  end
end
