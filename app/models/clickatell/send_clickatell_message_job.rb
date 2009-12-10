require 'uri'
require 'net/http'
require 'net/https'

class SendClickatellMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    config = channel.configuration
    
    uri = "/http/sendmsg"
    uri = append uri, 'api_id', config[:api_id], true
    uri = append uri, 'user', config[:user]
    uri = append uri, 'password', config[:password]
    # uri = append uri, 'from', msg.from
    uri = append uri, 'to', msg.to.without_protocol
    uri = append uri, 'text', msg.subject_and_body
    
    host = URI::parse('https://api.clickatell.com')
    
    request = Net::HTTP::new(host.host, host.port)
    request.use_ssl = true
    request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    result = ''
    begin
      response = request.get(uri)
      result = response.body[4 ... response.body.length]
    rescue => e
      ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
      msg.tries += 1
      msg.save
      raise
    else    
      msg.state = 'delivered'
      msg.tries += 1
      msg.save
    end
    
    result
  end
  
  def append(str, name, value, first = false)
    str += first ? '?' : '&'
    str += name
    str += '='
    str += CGI::escape(value)
    str
  end
end