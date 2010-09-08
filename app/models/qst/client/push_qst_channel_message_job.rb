class PushQstChannelMessageJob

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
    last_id = @client.get_last_id
    
    AOMessage.mark_older_as_confirmed last_id, :channel_id => @channel.id if last_id
  
    begin
      msgs = AOMessage.fetch_newer_messages(last_id, :desc => false, :batch_size => batch_size, :channel_id => @channel.id)
      return if msgs.empty?
      
      last_id = @client.put_messages AOMessage.to_qst(msgs)
      
      AOMessage.update_msgs_status msgs, @account.max_tries, last_id
      AOMessage.log_delivery msgs, @account, 'qst_client'
      
      @channel.invalidate_queued_ao_messages_count
      @channel.configuration[:last_ao_guid] = last_id
      @channel.save!
      
      return if msgs.length < batch_size
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      @channel.logger.error :channel_id => @channel.id, :message => "Push Qst messages received unauthorized"
    
      @channel.enabled = false
      @channel.save!
    else
      @channel.logger.error :channel_id => @channel.id, :message => "Push Qst messages received response code #{ex.response.code}"
    end
  end
  
end
