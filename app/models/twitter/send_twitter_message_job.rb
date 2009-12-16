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
    
    begin
      client = TwitterChannelHandler.new_client(config)
      client.direct_message_create(msg.to.without_protocol, msg.subject_and_body)
      # TODO: from the response get twitter message id and assign it
      # to channel_relative_id before saving the message
    rescue => e
      msg.tries += 1
      msg.save
      ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
      raise
    else
      msg.state = 'delivered'
      msg.tries += 1
      msg.save
    end
    
    ApplicationLogger.message_channeled msg, channel
  end
end