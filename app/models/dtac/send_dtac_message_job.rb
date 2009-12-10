class SendDtacMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    msg = AOMessage.find @message_id
	channel = Channel.find_by_id @channel_id
    return if msg.nil? or channel.nil?
	config = channel.configuration
	
	response = Net::HTTP.post_form(
		URI.parse('http://corpsms.dtac.co.th/servlet/com.iess.socket.SmsCorplink'), {
			'RefNo'=>msg.guid, 
			'Msn'=>msg.to.without_protocol,
			'Sno'=>config[:sno],
			'Msg'=>msg.subject_and_body,
			'Encoding'=>245,
			'MsgType'=>'E',
			'User' =>  config[:user],
			'Password' => config[:password]})
				
    if response.code[0,1] == "2" # success
	  msg.state = 'delivered'
	  msg.tries += 1
	  msg.save
	else
	  ApplicationLogger.exception_in_channel_and_ao_message channel, msg, response.message
      msg.tries += 1
      msg.save
      raise response.message
    end
    
    :success
  end
  
end