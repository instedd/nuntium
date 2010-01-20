class QstClientChannelHandler < ChannelHandler
  def handle(msg)
    QSTOutgoingMessage.create :ao_message_id => msg.id,
      :state => 'pending',
      :timestamp => msg.timestamp,
      :channel_id => @channel.id
  end
  
  def check_valid
    @channel.errors.add(:url, "can't be blank") if
        @channel.configuration[:url].nil? || @channel.configuration[:url].chomp.empty?
        
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
  end

  def after_save
    @channel.create_task('qst-client-channel-push', QST_PUSH_INTERVAL, PushQstChannelMessageJob.new(@channel.application_id, @channel.id))
    @channel.create_task('qst-client-channel-pull', QST_PULL_INTERVAL, PullQstChannelMessageJob.new(@channel.application_id, @channel.id))
  end

end