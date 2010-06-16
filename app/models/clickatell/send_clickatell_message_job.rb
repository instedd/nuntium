require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendClickatellMessageJob < SendMessageJob
  def managed_perform
    host = URI::parse('https://api.clickatell.com')
    
    request = Net::HTTP::new(host.host, host.port)
    request.use_ssl = true
    request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    result = ''
    response = request.get(uri)
    if response.body[0..2] == "ID:"
      @msg.channel_relative_id = response.body[4..-1]
      @msg.send_succeeed @account, @channel
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
  
  def uri
    params = {}
    params[:api_id] = @config[:api_id]
    params[:user] = @config[:user]
    params[:password] = @config[:password]
    unless @config[:from].blank?
      params[:from] = @config[:from]
      params[:mo] = '1'
    end
    params[:to] = @msg.to.without_protocol
    if is_low_ascii(@msg.subject_and_body)
      params[:text] = @msg.subject_and_body
    else
      params[:text] = to_unicode_raw_string(@msg.subject_and_body)
      params[:unicode] = '1'
    end
    params[:concat] = @config[:concat] unless @config[:concat].blank?
    "/http/sendmsg?#{params.to_query}"
  end
  
  def is_low_ascii(str)
    Chars.u_unpack(str).all? { |x| x < 128 }
  end
  
  def to_unicode_raw_string(str)
    chars = Chars.u_unpack(str).map { |x| x.to_s(16).rjust(4, '0') }
    chars.to_s
  end
end
