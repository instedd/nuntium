class ClickatellChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendClickatellMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
end

class SendClickatellMessageJob < Struct.new(:application_id, :channel_id, :message_id)
  def perform
    channel = Channel.find self.channel_id
    msg = AOMessage.find self.message_id
    config = channel.configuration
    
    uri = "https://api.clickatell.com/http/sendmsg"
    uri = append uri, 'api_id', config[:api_id], true
    uri = append uri, 'user', config[:user]
    uri = append uri, 'password', config[:password]
    # uri = append uri, 'from', msg.from
    uri = append uri, 'to', msg.to
    uri = append uri, 'text', msg.subject_and_body
    
    response = Net::HTTP.request_get(uri)
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