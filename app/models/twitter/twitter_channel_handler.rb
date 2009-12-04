require 'twitter'

class TwitterChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendTwitterMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def update(params)
    @channel.configuration[:welcome_message] = params[:configuration][:welcome_message]
  end
  
  def self.new_oauth
    oauth = Twitter::OAuth.new(TwitterConsumerConfig['token'], TwitterConsumerConfig['secret'])
    oauth.set_callback_url(TwitterConsumerConfig['callback_url'])
    oauth
  end
  
  def self.new_client(config)
    oauth = TwitterChannelHandler.new_oauth
    oauth.authorize_from_access(config[:token], config[:secret])
    
    Twitter::Base.new(oauth)
  end
  
  def info
    @channel.configuration[:screen_name]
  end
  
  def after_create
    @channel.create_task('twitter-receive', TWITTER_RECEIVE_INTERVAL, ReceiveTwitterMessageJob.new(@channel.application_id, @channel.id))
  end
  
end
