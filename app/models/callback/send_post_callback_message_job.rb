require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendPostCallbackMessageJob
  attr_accessor :application_id, :message_id

  def initialize(application_id, message_id)
    @application_id = application_id
    @message_id = message_id
    
    app = Application.find_by_id @application_id
    app.logger.info :at_message_id => @message_id, :message => "HTTP POST callback enqueded"
  end

  def perform
    app = Application.find_by_id @application_id
    msg = ATMessage.get_message @message_id
    
    app.logger.info :at_message_id => @message_id, :message => "HTTP POST callback processed"
    
    url = URI.parse(app.configuration[:url])
    req = Net::HTTP::Post.new(url.path)
    if app.configuration[:cred_user].present?
      req.basic_auth app.configuration[:cred_user], app.configuration[:cred_pass]
    end
    req.content_type = "application/x-www-form-urlencoded"

    data = { :application_id => app.id, 
      :from => msg.from, :to => msg.to, 
      :subject => msg.subject, 
      :body => msg.body, 
      :guid => msg.guid }
    req.set_form_data(data)
    
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        ATMessage.update_tries([msg.id],'delivered')
        ATMessage.log_delivery([msg], app, 'http_post_callback')
      else
        ATMessage.update_tries([msg.id],'failed')
        app.logger.error :at_message_id => @message_id, :message => "HTTP POST callback failed #{res.error!}"
        raise res.error!
    end
  end
end
