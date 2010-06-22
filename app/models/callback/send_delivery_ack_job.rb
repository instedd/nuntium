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
    
    data = {:guid => msg.guid, :channel => chan.name, :state => @state}
    
    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}
    if app.delivery_ack_user.present?
      options[:user] = app.delivery_ack_user
      options[:password] = app.delivery_ack_password
    end
    
    res = RestClient::Resource.new app.delivery_ack_url, options
    res = if app.delivery_ack_method == 'get'
      res["?#{data.to_query}"].get
    else
      res.post data
    end
    res = res.net_http_res
    
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return
      when Net::HTTPUnauthorized
        app.alert "Sending HTTP delivery ack received unauthorized: invalid credentials"
        app.delivery_ack_method = 'none'
        app.save!
        return
      else
        account.logger.error :ao_message_id => @message_id, :message => "HTTP delivery ack failed #{res.error!}"
        raise res.error!
    end
  end
end
