require 'uri'
require 'net/http'

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
  
  def get_credit
    cfg = @channel.configuration
    uri = "/http/getbalance?api_id=#{cfg[:api_id]}&user=#{cfg[:user]}&password=#{cfg[:password]}"
    host = URI::parse('http://api.clickatell.com')
    Net::HTTP::new(host.host, host.port).get(uri).body
  end
end
