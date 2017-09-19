#!ruby
class SendMessengerMessageJob < SendMessageJob
  def managed_perform
    # Here you have:
    # @msg: the AO message to be sent. Most notably, you will use
    #       the from, to, subject and body accessors. You also have
    #       the subject_and_body accessor that combines both subject
    #       and body with a dash.
    # @account
    # @channel
    # @config: convenience variable that holds the channel's configuration

    # Do whatever you want with the message...
    # For example, issue an HTTP get with it:


    recipient = @msg.to
    recipient.sub! 'sms://', ''

    data = { 
      :recipient => { 
        :id => recipient
       }, 
      :message => { 
        :text => @msg.subject_and_body
      }
    }
    

    url = "https://graph.facebook.com/me/messages?access_token="+@channel.page_access_token
    res = RestClient::Resource.new(url).post data
    netres = res.net_http_res
    
    case netres
    when Net::HTTPSuccess, Net::HTTPRedirection
      # Message was sent, must return "true"
      return true
    when Net::HTTPUnauthorized
      # Message was not sent, but it's a channel's problem.
      # Must raise a PermanentException
      raise PermamentException.new(Exception.new "unauthorized")
    else
      # Something else went wrong, probably something's wrong with
      # the message or a temporary error...
      # Must raise an Exception
      raise Exception.new("Something's wrong...")
    end
  end
end