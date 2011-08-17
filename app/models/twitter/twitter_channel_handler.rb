require 'twitter'

class TwitterChannelHandler < GenericChannelHandler
  def update(params)
    super
    @channel.configuration[:welcome_message] = params[:configuration][:welcome_message]
  end

  def self.new_oauth
    oauth = Twitter::OAuth.new(Nuntium::TwitterConsumerConfig['token'], Nuntium::TwitterConsumerConfig['secret'])
    oauth.set_callback_url(Nuntium::TwitterConsumerConfig['callback_url'])
    oauth
  end

  def self.new_client(config)
    oauth = TwitterChannelHandler.new_oauth
    oauth.authorize_from_access(config[:token], config[:secret])

    Twitter::Base.new(oauth)
  end

  def friendship_create(user, follow)
    client = TwitterChannelHandler.new_client(@channel.configuration)
    if not client.friendship_exists?(user, @channel.configuration[:screen_name])
      client.friendship_create user, follow
    end
  end

  def info
    @channel.configuration[:screen_name] +
      " <a href=\"#\" onclick=\"twitter_view_rate_limit_status(#{@channel.id}); return false;\">view rate limit status</a>"
  end

  def get_rate_limit_status
    client = TwitterChannelHandler.new_client @channel.configuration
    stat = client.rate_limit_status
    "Hourly limit: #{stat.hourly_limit}, Remaining hits for this hour: #{stat.remaining_hits}"
  end

  def on_create
    super
    if @channel.enabled
      @channel.create_task 'twitter-receive', TWITTER_RECEIVE_INTERVAL,
        ReceiveTwitterMessageJob.new(@channel.account_id, @channel.id)
    end
  end

  def on_enable
    super
    @channel.create_task 'twitter-receive', TWITTER_RECEIVE_INTERVAL,
      ReceiveTwitterMessageJob.new(@channel.account_id, @channel.id)
  end

  def on_disable
    super
    @channel.drop_task('twitter-receive')
  end

  def on_pause
    super
    @channel.drop_task('twitter-receive')
  end

  def on_resume
    super
    @channel.create_task 'twitter-receive', TWITTER_RECEIVE_INTERVAL,
      ReceiveTwitterMessageJob.new(@channel.account_id, @channel.id)
  end

  def on_destroy
    super
    if @channel.enabled
      @channel.drop_task('twitter-receive')
    end
  end

end
