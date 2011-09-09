require 'twilio-ruby'

class SendTwilioMessageJob < SendMessageJob
  def managed_perform
    client = Twilio::REST::Client.new @config[:account_sid], @config[:auth_token]
    begin
      response = client.account.sms.messages.create sms_params
      @msg.channel_relative_id = response.sid
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
      :status_callback => ack_callback
    }
  end

  def ack_callback
    uri = URI.parse(NamedRoutes.twilio_ack_url(@account))
    uri.userinfo = "#{@channel.name}:#{@config[:incoming_password]}"
    uri.to_s
  end
end
