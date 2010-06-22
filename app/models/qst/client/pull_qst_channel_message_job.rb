class PullQstChannelMessageJob

  include CronTask::QuotedTask
  
  attr_accessor :batch_size
  
  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
    @batch_size = 10
  end
  
  def perform
    @account = Account.find_by_id(@account_id)
    @channel = @account.find_channel @channel_id
    
    @client = QstClient.new @channel.configuration[:url], @channel.configuration[:user], @channel.configuration[:password]
    
    options = {:max => batch_size}
    
    begin
      options[:from_id] = @channel.configuration[:last_at_guid] if @channel.configuration[:last_at_guid]
      
      msgs = @client.get_messages options
      msgs = ATMessage.from_qst msgs
      
      return if msgs.empty?
      
      msgs.each do |msg|
        @account.route_at msg, @channel
      end
      @channel.configuration[:last_at_guid] = msgs.last.guid
      @channel.save!
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      @channel.logger.error :channel_id => @channel.id, :message => "Pull Qst messages received unauthorized"
    
      @channel.enabled = false
      @channel.save!
    else
      @channel.logger.error :channel_id => @channel.id, :message => "Pull Qst messages received response code #{ex.response.code}"
    end
  end
end
