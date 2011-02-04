class SendDeliveryAckJob
  attr_accessor :account_id, :application_id, :message_id, :state, :tries

  def initialize(account_id, application_id, message_id, state, tries = 0)
    @account_id = account_id
    @application_id = application_id
    @message_id = message_id
    @state = state
    @tries = tries
  end

  def perform
    @account = Account.find_by_id @account_id
    @app = @account.find_application @application_id
    @msg = AOMessage.get_message @message_id
    @chan = @account.find_channel @msg.channel_id

    return unless @app and @chan and @app.delivery_ack_method != 'none'

    data = {:guid => @msg.guid, :channel => @chan.name, :state => @state}.merge(@msg.custom_attributes)

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}
    if @app.delivery_ack_user.present?
      options[:user] = @app.delivery_ack_user
      options[:password] = @app.delivery_ack_password
    end

    begin
      res = RestClient::Resource.new @app.delivery_ack_url, options
      res = @app.delivery_ack_method == 'get' ? res["?#{data.to_query}"].get : res.post(data)
      res = res.net_http_res

      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          return
        when Net::HTTPUnauthorized
          alert_msg = "Sending HTTP delivery ack received unauthorized: invalid credentials"
          @app.alert alert_msg
          raise alert_msg
        else
          raise "HTTP delivery ack failed: #{res.error!}"
      end
    rescue RestClient::BadRequest
      @app.logger.warning :ao_message_id => @message_id, :message => "Received HTTP Bad Request (404) for delivery ack"
    end
  end

  def reschedule(ex)
    @app.logger.warning :ao_message_id => @message_id, :message => ex.message

    new_job = self.class.new(@account_id, @application_id, @message_id, @state, self.tries + 1)
    ScheduledJob.create! :job => RepublishApplicationJob.new(@application_id, new_job), :run_at => 1.minute.from_now
  end
end
