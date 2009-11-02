require 'uri'
require 'net/http'
require 'net/https'

class SendClickatellMessageJob < Struct.new(:application_id, :channel_id, :message_id)

  def perform
    channel = Channel.find self.channel_id
    msg = AOMessage.find self.message_id
    config = channel.configuration
    
    uri = "/http/sendmsg"
    uri = append uri, 'api_id', config[:api_id], true
    uri = append uri, 'user', config[:user]
    uri = append uri, 'password', config[:password]
    # uri = append uri, 'from', msg.from
    uri = append uri, 'to', msg.to_without_protocol
    uri = append uri, 'text', msg.subject_and_body
    
    host = URI::parse('https://api.clickatell.com')
    
    request = Net::HTTP::new(host.host, host.port)
    request.use_ssl = true
    request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    response = request.get(uri)
    result = response.body[4 ... response.body.length]
    
    AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])
    
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