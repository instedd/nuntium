class SendMultimodemIsmsMessageJob < SendMessageJob
  def managed_perform
    url = "http://#{@config[:host]}"
    url << ":#{@config[:port]}" if @config[:port].present?
    url << "/sendmsg?"
    url << "user=#{CGI.escape(@config[:user])}&"
    url << "passwd=#{CGI.escape(@config[:password])}&"
    url << "cat=1&"
    url << "to=#{CGI.escape(@msg.to.without_protocol)}&"
    url << "text=#{CGI.escape(@msg.subject_and_body)}"

    response = RestClient.get url
    if response.body[0..2] == "ID:"
      @msg.channel_relative_id = response.body[4..-1]
      @msg.send_succeeed @account, @channel
      return true
    elsif response.body[0..3] == "Err:"
      code_with_description = response.body[5..-1]
      code = code_with_description.to_i
      error = MultimodemIsmsChannelHandler::ERRORS[code]

      raise code_with_description if error.nil?
      raise PermanentException.new(Exception.new(code_with_description)) if error[:kind] == :fatal
      raise MessageException.new(Exception.new(code_with_description)) if error[:kind] == :message
      raise code_with_description
    else
      raise response.body
    end
  end
end
