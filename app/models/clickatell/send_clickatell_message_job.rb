include ActiveSupport::Multibyte

class SendClickatellMessageJob < SendMessageJob
  def managed_perform
    response = Clickatell.send_message query_parameters
    if response.body[0..2] == "ID:"
      @msg.channel_relative_id = response.body[4..-1]
      @msg.send_succeed @account, @channel
    elsif response.body[0..3] == "ERR:"
      code_with_description = response.body[5..-1]
      code = code_with_description.to_i
      error = ClickatellChannel::CLICKATELL_ERRORS[code]

      raise code_with_description if error.nil?
      raise PermanentException.new(Exception.new(code_with_description)) if error[:kind] == :fatal
      raise MessageException.new(Exception.new(code_with_description)) if error[:kind] == :message
      raise code_with_description
    else
      raise response.body
    end
  end

  def query_parameters
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
    params[:climsgid] = @msg.guid.gsub('-', '')
    params[:concat] = @config[:concat] unless @config[:concat].blank?
    params[:callback] = '3'
    params
  end

  def is_low_ascii(str)
    Chars.u_unpack(str).all? { |x| x < 128 }
  end

  def to_unicode_raw_string(str)
    chars = Chars.u_unpack(str).map { |x| x.to_s(16).rjust(4, '0') }
    chars.to_s
  end
end
