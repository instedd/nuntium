class QstClientChannelHandler < ChannelHandler
  def handle(msg)
    # AO Message should be queued, we just query them
  end

  def check_valid
    check_config_not_blank :url, :user, :password
  end

  def on_enable
    @channel.create_task('qst-client-channel-push', QST_PUSH_INTERVAL, PushQstChannelMessageJob.new(@channel.account_id, @channel.id))
    @channel.create_task('qst-client-channel-pull', QST_PULL_INTERVAL, PullQstChannelMessageJob.new(@channel.account_id, @channel.id))
  end

  def on_disable
    @channel.drop_task('qst-client-channel-push')
    @channel.drop_task('qst-client-channel-pull')
  end

  def on_destroy
    on_disable
  end

  def on_pause
    on_disable
  end

  def on_unpause
    on_enable
  end

end
