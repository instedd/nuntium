class SendTwilioMessageJob < SendMessageJob  
  def managed_perform
    client = Twilio::REST::Client.new @config[:account_sid], @config[:auth_token]
    begin
      response = client.account.sms.messages.create sms_params
      @msg.channel_relative_id = response.sid
      @msg.send_succeeed @account, @channel
    rescue Twilio::REST::RequestError => e
      if e.message == 'Authenticate'
        raise PermanentException.new(e)
      else
        raise MessageException.new(e)
      end
    rescue Twilio::REST::ServerError => e
      raise MessageException.new(e)
    end
  end
  
  def sms_params
    {
      :from => @config[:from],
      :to => @msg.to.without_protocol,
      :body => @msg.subject_and_body,
      :status_callback => NamedRoutes.twilio_ack_url(@account)
    }
  end
end