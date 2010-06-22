class PullQstMessageJob

  include CronTask::QuotedTask
  
  attr_accessor :batch_size
  
  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end
  
  def perform
    @application = Application.find_by_id(@application_id)
    @client = QstClient.new @application.interface_url, @application.interface_user, @application.interface_password
    
    options = {:max => batch_size}
    
    begin
      options[:from_id] = @application.last_ao_guid if @application.last_ao_guid
      
      msgs = @client.get_messages options
      msgs = AOMessage.from_qst msgs
      
      return if msgs.empty?
      
      msgs.each do |msg|
        @application.route_ao msg, 'qst_client'
      end
      @application.last_ao_guid = msgs.last.guid
      @application.save!
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      @application.logger.error :application_id => @application.id, :message => "Pull Qst messages received unauthorized"
    
      @application.interface = 'rss'
      @application.save!
    else
      @application.logger.error :application_id => @application.id, :message => "Pull Qst messages received response code #{ex.response.code}"
    end
  end
end
