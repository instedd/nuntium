require 'twitter'

class TwitterChannelHandler < ChannelHandler
  def handle(msg)
    config = @channel.configuration
  
    oauth = TwitterChannelHandler.new_oauth
    oauth.authorize_from_access(config[:token], config[:secret])
    
    client = Twitter::Base.new(oauth)
    client.direct_message_create(msg.to.without_protocol, msg.subject_and_body)
    
    AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])
  end
  
  def update(params)
    @channel.configuration[:welcome_message] = params[:configuration][:welcome_message]
  end
  
  def self.new_oauth
    oauth = Twitter::OAuth.new(TwitterConsumerConfig['token'], TwitterConsumerConfig['secret'])
    oauth.set_callback_url(TwitterConsumerConfig['callback_url'])
    oauth
  end
end
