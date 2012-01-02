require 'twilio-ruby'

class SendTwilioMessageJob < SendMessageJob
  @@max_length = 160

  def managed_perform
    @client = Twilio::REST::Client.new @config[:account_sid], @config[:auth_token]
    begin
      message_text = @msg.subject_and_body

      # Send first part of the message and store relative id
      response = send_message(message_text)
      @msg.channel_relative_id = response.sid

      # Continue sending other portions of the message
      while message_text.length > 0
        send_message(message_text)
      end
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

  private

  def send_message(text)
    part = text.slice!(0..(@@max_length-1))
    @client.account.sms.messages.create sms_params(part)
  end

  def sms_params(body)
    {
      :from => @config[:from],
      :to => @msg.to.without_protocol,
      :body => body,
      :status_callback => ack_callback
    }
  end

  def ack_callback
    uri = URI.parse(NamedRoutes.twilio_ack_url(@account))
    uri.userinfo = "#{@channel.name}:#{@config[:incoming_password]}"
    uri.to_s
  end
end
