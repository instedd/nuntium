class SendTwitterMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    app = Application.find_by_id @application_id
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    config = channel.configuration
    
    begin
      client = TwitterChannelHandler.new_client(config)
      response = client.direct_message_create(msg.to.without_protocol, msg.subject_and_body)
      msg.channel_relative_id = response.id
    rescue => e
      msg.send_failed app, channel, e
    else
      msg.send_succeeed app, channel
    end
  end
end
