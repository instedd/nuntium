class TwitterChannelHandler < ChannelHandler
  def handle(msg)
  end
  
  def update(params)
    @channel.configuration[:welcome_message] = params[:configuration][:welcome_message]
  end
end
