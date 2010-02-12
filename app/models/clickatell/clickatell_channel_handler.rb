require 'uri'
require 'net/http'
require 'net/https'

class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue create_job(msg)
  end
  
  def handle_now(msg)
    create_job(msg).perform
  end
  
  def create_job(msg)
    SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    check_config_not_blank :api_id
    
    if (@channel.direction & Channel::Incoming) != 0    
      check_config_not_blank :incoming_password
    end
    
    if (@channel.direction & Channel::Outgoing) != 0
      check_config_not_blank :user, :password, :from
    end
  end
  
  def info
    @channel.configuration[:user] + " / " + @channel.configuration[:api_id] +
      " <a href=\"#\" onclick=\"clickatell_view_credit(#{@channel.id}); return false;\">view credit</a>"
  end
  
  def more_info(ao_msg)
    return {} if ao_msg.channel_relative_id.nil?
    
    begin
      status = get_status(ao_msg)
      idx = status.index 'Status:'
      if idx == -1
        {'Clickatell status' => status}
      else
        status = status[idx + 7 .. -1].strip
        codes = @@clickatellStatuses[status]
        if codes.nil?
          {'Clickatell status' => status}
        else
          {
            'Clickatell status description' => codes[0],
            'Clickatell status detail' => codes[1]
          }
        end
      end
    rescue Exception => ex
      {'Clickatell status' => 'error retreiving status: #{ex}'}
    end
  end
  
  def get_credit
    cfg = @channel.configuration
    uri = "/http/getbalance?api_id=#{cfg[:api_id]}&user=#{cfg[:user]}&password=#{cfg[:password]}"
    host = URI::parse('http://api.clickatell.com')
    Net::HTTP::new(host.host, host.port).get(uri).body
  end
  
  def get_status(ao_msg)
    cfg = @channel.configuration
    uri = "/http/querymsg?api_id=#{cfg[:api_id]}&user=#{cfg[:user]}&password=#{cfg[:password]}&apimsgid=#{ao_msg.channel_relative_id}"
    host = URI::parse('https://api.clickatell.com')
    request = Net::HTTP::new(host.host, host.port)
    request.use_ssl = true
    request.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request.get(uri).body
  end
  
  @@clickatellStatuses = {
    '001' => ['Message unknown', 'The message ID is incorrect or reporting is delayed.'],
    '002' => ['Message queued', 'The message could not be delivered and has been queued for attempted redelivery.'],
    '003' => ['Delivered to gateway', 'Delivered to the upstream gateway or network (delivered to the recipient).'],
    '004' => ['Received by recipient', 'Confirmation of receipt on the handset of the recipient.'],
    '005' => ['Error with message', 'There was an error with the message, probably caused by the content of the message itself.'],
    '006' => ['User cancelled message delivery', 'The message was terminated by a user (stop message command) or by our staff.'],
    '007' => ['Error delivering message', 'An error occurred delivering the message to the handset.'],
    '008' => ['OK', 'Message received by gateway.'],
    '009' => ['Routing error', 'The routing gateway or network has had an error routing the message.'],
    '010' => ['Message expired', 'Message has expired before we were able to deliver it to the upstream gateway. No charge applies.'],
    '00A' => ['Message expired', 'Message has expired before we were able to deliver it to the upstream gateway. No charge applies.'],
    '011' => ['Message queued for later delivery', 'Message has been queued at the gateway for delivery at a later time (delayed delivery).'],
    '00B' => ['Message queued for later delivery', 'Message has been queued at the gateway for delivery at a later time (delayed delivery).'],
    '012' => ['Out of credit', 'The message cannot be delivered due to a lack of funds in your account. Please re-purchase credits.'],
    '00C' => ['Out of credit', 'The message cannot be delivered due to a lack of funds in your account. Please re-purchase credits.']
    }
end
