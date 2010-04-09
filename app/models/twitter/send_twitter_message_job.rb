class SendTwitterMessageJob < SendMessageJob
  def managed_perform
    begin
      client = TwitterChannelHandler.new_client(@config)
      response = client.direct_message_create(@msg.to.without_protocol, @msg.subject_and_body)
      @msg.channel_relative_id = response.id
    rescue => e
      @msg.send_failed @app, @channel, e
    else
      @msg.send_succeeed @app, @channel
    end
  end
end
