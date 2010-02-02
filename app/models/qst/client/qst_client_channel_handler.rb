class QstClientChannelHandler < ChannelHandler
  def handle(msg)
    # AO Message should be queued, we just query them
  end
  
  def check_valid
    @channel.errors.add(:url, "can't be blank") if
        @channel.configuration[:url].blank?
        
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].blank?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].blank?
  end

  def on_enable
    @channel.create_task('qst-client-channel-push', QST_PUSH_INTERVAL, PushQstChannelMessageJob.new(@channel.application_id, @channel.id))
    @channel.create_task('qst-client-channel-pull', QST_PULL_INTERVAL, PullQstChannelMessageJob.new(@channel.application_id, @channel.id))
  end
  
  def on_disable
    @channel.drop_task('qst-client-channel-push')
    @channel.drop_task('qst-client-channel-pull')
  end
  
  def on_destroy
    on_disable
  end

end