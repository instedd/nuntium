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
  
    oauth = TwitterChannelHandler.new_oauth
    oauth.authorize_from_access(config[:token], config[:secret])
    
    client = Twitter::Base.new(oauth)
    client.direct_message_create(msg.to.without_protocol, msg.subject_and_body)
    
    AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])
  end
end