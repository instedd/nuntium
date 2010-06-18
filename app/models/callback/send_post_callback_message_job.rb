class SendPostCallbackMessageJob
  attr_accessor :account_id, :application_id, :message_id

  def initialize(account_id, application_id, message_id)
    @account_id = account_id
    @application_id = application_id
    @message_id = message_id
  end

  def perform
    account = Account.find_by_id @account_id
    app = account.find_application @application_id
    msg = ATMessage.get_message @message_id
    
    headers = {:content_type => "application/x-www-form-urlencoded"}
    if app.interface_user.present?
      headers[:user] = app.interface_user
      headers[:password] = app.interface_password
    end

    data = { 
      :application => app.name, 
      :from => msg.from,
      :to => msg.to, 
      :subject => msg.subject, 
      :body => msg.body, 
      :guid => msg.guid,
      :channel => msg.channel.name 
    }
    
    res = RestClient.post app.interface_url, data, headers
    res = res.net_http_res
    
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        ATMessage.update_tries([msg.id],'delivered')
        ATMessage.log_delivery([msg], account, 'http_post_callback')
        return true
        
      when Net::HTTPUnauthorized
        app.alert "Sending HTTP POST callback received unauthorized: invalid credentials"
    
        app.interface = 'rss'
        app.save!
        return false
      else
        ATMessage.update_tries([msg.id],'failed')
        #TODO check if this error is logged
        account.logger.error :at_message_id => @message_id, :message => "HTTP POST callback failed #{res.error!}"
        raise res.error!
    end
  end
end
