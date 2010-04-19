require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendClickatellMessageJob < SendMessageJob
  def managed_perform
    uri = "/http/sendmsg"
    uri = append uri, 'api_id', @config[:api_id], true
    uri = append uri, 'user', @config[:user]
    uri = append uri, 'password', @config[:password]
    unless @config[:from].blank?
      uri = append uri, 'from', @config[:from]
      uri = append uri, 'mo', '1'
    end
    uri = append uri, 'to', @msg.to.without_protocol
    if is_low_ascii(@msg.subject_and_body)
      uri = append uri, 'text', @msg.subject_and_body
    else
      uri = append uri, 'text', to_unicode_raw_string(@msg.subject_and_body)
      uri = append uri, 'unicode', '1'
    end
    unless @config[:concat].blank?
      uri = append uri, 'concat', @config[:concat]
    end
    
    host = URI::parse('https://api.clickatell.com')
    
    request = Net::HTTP::new(host.host, host.port)
    request.use_ssl = true
    request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    result = ''
    response = request.get(uri)
    if response.body[0..2] == "ID:"
      @msg.channel_relative_id = response.body[4..-1]
      @msg.send_succeeed @app, @channel
    elsif response.body[0..3] == "ERR:"
      code_with_description = response.body[5..-1]
      code = code_with_description.to_i
      error = ClickatellChannelHandler::CLICKATELL_ERRORS[code]
      
      raise code_with_description if error.nil?
      raise PermanentException.new(Exception.new(code_with_description)) if error[:kind] == :fatal
      raise MessageException.new(Exception.new(code_with_description)) if error[:kind] == :message
      raise code_with_description
    else
      raise response.body
    end   
  end
  
  def append(str, name, value, first = false)
    str << (first ? '?' : '&')
    str << name
    str << '='
    str << CGI::escape(value)
    str
  end
  
  def is_low_ascii(str)
    Chars.u_unpack(str).all? { |x| x < 128 }
  end
  
  def to_unicode_raw_string(str)
    chars = Chars.u_unpack(str).map { |x| x.to_s(16).rjust(4, '0') }
    chars.to_s
  end
end
