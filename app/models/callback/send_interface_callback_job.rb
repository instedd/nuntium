class SendInterfaceCallbackJob
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
      :from => msg.from,
      :to => msg.to,
      :subject => msg.subject,
      :body => msg.body,
      :guid => msg.guid,
      :channel => msg.channel.name
    }.merge(msg.custom_attributes)

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}
    if app.interface_user.present?
      options[:user] = app.interface_user
      options[:password] = app.interface_password
    end

    res = RestClient::Resource.new(app.interface_url, options)
    res = if app.interface == 'http_get_callback'
            res["?#{data.to_query}"].get
          else
            res.post data
          end
    netres = res.net_http_res

    case netres
      when Net::HTTPSuccess, Net::HTTPRedirection
        ATMessage.update_tries([msg.id],'delivered')
        ATMessage.log_delivery([msg], account, 'http_post_callback')

        # If the response includes a body, create an AO message from it
        if res.body.present?
          reply = AOMessage.new :from => msg.to, :to => msg.from, :body => res.body
          app.route_ao reply, 'http post callback'
        end

        return true
      when Net::HTTPBadRequest
        msg.send_failed account, app, "Received HTTP Bad Request (404)"
        return true
      when Net::HTTPUnauthorized
        app.alert "Sending HTTP POST callback received unauthorized: invalid credentials"

        app.interface = 'rss'
        app.save!
        return false
      else
        alert_msg = "HTTP POST callback failed #{netres.error!}"
        app.alert alert_msg

        ATMessage.update_tries([msg.id],'failed')
        #TODO check if this error is logged
        account.logger.error :at_message_id => @message_id, :message => alert_msg
        raise netres.error!
    end
  end

  def to_s
    "<SendInterfaceCallbackMessageJob:#{@message_id}>"
  end
end
