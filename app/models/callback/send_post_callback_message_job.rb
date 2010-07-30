require 'cgi'

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
    return true if msg.state != 'queued'

    data = { 
      :application => app.name, 
      :from => encode(msg.from),
      :to => encode(msg.to), 
      :subject => encode(msg.subject), 
      :body => encode(msg.body), 
      :guid => encode(msg.guid),
      :channel => msg.channel.name 
    }

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}
    if app.interface_user.present?
      options[:user] = app.interface_user
      options[:password] = app.interface_password
    end
    
    res = RestClient::Resource.new(app.interface_url, options).post data
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
  
  def encode(str)
    str = CGI.escape(str) if str
    str
  end

  def to_s
    "<SendPostCallbackMessageJob:#{@message_id}>"
  end
end
