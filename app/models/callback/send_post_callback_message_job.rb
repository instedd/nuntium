require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendPostCallbackMessageJob
  attr_accessor :account_id, :message_id

  def initialize(account_id, message_id)
    @account_id = account_id
    @message_id = message_id
  end

  def perform
    account = Account.find_by_id @account_id
    msg = ATMessage.get_message @message_id
    
    url = URI.parse(account.interface_url)
    req = Net::HTTP::Post.new(url.path)
    if account.interface_user.present?
      req.basic_auth account.interface_user, account.interface_password
    end
    req.content_type = "application/x-www-form-urlencoded"

    data = { :account_id => account.id, 
      :from => msg.from, :to => msg.to, 
      :subject => msg.subject, 
      :body => msg.body, 
      :guid => msg.guid }
    req.set_form_data(data)
    
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        ATMessage.update_tries([msg.id],'delivered')
        ATMessage.log_delivery([msg], account, 'http_post_callback')
      when Net::HTTPUnauthorized
        account.alert "Sending HTTP POST callback received unauthorized: invalid credentials"
    
        account.interface = 'rss'
        account.save!
        return
      else
        ATMessage.update_tries([msg.id],'failed')
        account.logger.error :at_message_id => @message_id, :message => "HTTP POST callback failed #{res.error!}"
        raise res.error!
    end
  end
end
