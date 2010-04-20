class SendTwitterMessageJob < SendMessageJob
  def managed_perform
    client = TwitterChannelHandler.new_client(@config)
    response = client.direct_message_create(@msg.to.without_protocol, @msg.subject_and_body)
    @msg.channel_relative_id = response.id
    @msg.send_succeeed @account, @channel
  rescue Twitter::NotFound => ex
    raise MessageException.new(ex)
  rescue Twitter::Unauthorized => ex
    raise PermanentException.new(ex)
  end
end
