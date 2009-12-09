class SendDtacMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    msg = AOMessage.find @message_id
    
    host = URI::parse('https://corpsms.dtac.co.th/servlet/com.iess.socket.SmsCorplink')
    
    request = Net::HTTP::Post.new(host.path)
    
	#request.basic_auth 'api1610368', 'u41jjmew'
    request.set_form_data({
					'RefNo'=>msg.guid, 
					'Msn'=>msg.to.without_protocol,
					'Sno'=>'1677',
					'Msg'=>msg.subject_and_body,
					'Encoding'=>245,
					'MsgType'=>'E',
					'User' => 'api1610368',
					'Password' => 'u41jjmew'
				}, ';')
	
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }

    result = ''
    begin
      result = response.body[4 ... response.body.length]
    rescue => e
      ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
      msg.tries += 1;
      msg.save
      raise
    else    
      msg.state = 'delivered'
      msg.tries += 1
      msg.save
    end
    
    result
  end
  
end