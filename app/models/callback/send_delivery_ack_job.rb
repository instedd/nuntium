require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendDeliveryAckJob
  attr_accessor :account_id, :application_id, :message_id, :state

  def initialize(account_id, application_id, message_id, state)
    @account_id = account_id
    @application_id = application_id
    @message_id = message_id
    @state = state
  end

  def perform
    account = Account.find_by_id @account_id
    app = account.find_application @application_id
    msg = AOMessage.get_message @message_id
    chan = account.find_channel msg.channel_id
    
    return unless app and chan and app.delivery_ack_method != 'none' 
    
    url = URI.parse(app.delivery_ack_url)
    req = nil
    
    data = {:guid => msg.guid, :channel => chan.name, :state => @state}
    if app.delivery_ack_method == 'get'
      req = Net::HTTP::Get.new("#{url.path}?#{data.to_query}")
    else
      req = Net::HTTP::Post.new(url.path.present? ? url.path : '/')
      req.set_form_data(data)
    end
    
    if app.delivery_ack_user.present?
      req.basic_auth app.delivery_ack_user, app.delivery_ack_password
    end
    req.content_type = "application/x-www-form-urlencoded"
    
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return
      when Net::HTTPUnauthorized
        application.alert "Sending HTTP delivery ack received unauthorized: invalid credentials"
        application.delivery_ack_method = 'none'
        application.save!
        return
      else
        account.logger.error :ao_message_id => @message_id, :message => "HTTP delivery ack failed #{res.error!}"
        raise res.error!
    end
  end
end
