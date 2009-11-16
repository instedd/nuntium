class SendTwitterMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    config = channel.configuration
    
    client = TwitterChannelHandler.new_client(config)
    client.direct_message_create(msg.to.without_protocol, msg.subject_and_body)
    
    AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])
  end
end