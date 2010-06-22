class PushQstMessageJob

  include CronTask::QuotedTask
  
  attr_accessor :batch_size
  
  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end
  
  def perform
    @application = Application.find_by_id(@application_id)
    @client = QstClient.new @application.interface_url, @application.interface_user, @application.interface_password
    last_id = @client.get_last_id
    
    ATMessage.mark_older_as_confirmed last_id, :account_id => @application.account_id if last_id
  
    begin
      msgs = ATMessage.fetch_newer_messages(last_id, :desc => false, :batch_size => batch_size, :account_id => @application.account_id)
      return if msgs.empty?
      
      last_id = @client.put_messages ATMessage.to_qst(msgs)
      
      ATMessage.update_msgs_status msgs, @application.account.max_tries, last_id
      ATMessage.log_delivery msgs, @application.account, 'qst_client'
      
      @application.last_at_guid = last_id
      @application.save!
      
      return if msgs.length < batch_size
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      @application.logger.error :application_id => @application.id, :message => "Push Qst messages received unauthorized"
    
      @application.interface = 'rss'
      @application.save!
    else
      @application.logger.error :application_id => @application.id, :message => "Push Qst messages received response code #{ex.response.code}"
    end
  end
  
end
