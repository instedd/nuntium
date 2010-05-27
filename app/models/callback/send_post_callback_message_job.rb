require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

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
    
    url = URI.parse(app.interface_url)
    req = Net::HTTP::Post.new(url.path)
    if app.interface_user.present?
      req.basic_auth app.interface_user, app.interface_password
    end
    req.content_type = "application/x-www-form-urlencoded"

    data = { 
      :application => app.name, 
      :from => msg.from,
      :to => msg.to, 
      :subject => msg.subject, 
      :body => msg.body, 
      :guid => msg.guid 
    }
    req.set_form_data(data)
    
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        ATMessage.update_tries([msg.id],'delivered')
        ATMessage.log_delivery([msg], account, 'http_post_callback')
      when Net::HTTPUnauthorized
        app.alert "Sending HTTP POST callback received unauthorized: invalid credentials"
    
        app.interface = 'rss'
        app.save!
        return
      else
        ATMessage.update_tries([msg.id],'failed')
        #TODO check if this error is logged
        account.logger.error :at_message_id => @message_id, :message => "HTTP POST callback failed #{res.error!}"
        raise res.error!
    end
  end
end
