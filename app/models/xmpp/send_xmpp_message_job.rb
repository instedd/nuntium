class SendXmppMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end
  
  def perform(delegate)
    app = Application.find_by_id @application_id
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    
    from = msg.from.without_protocol
    to = msg.to.without_protocol
    subject = msg.subject
    body = msg.body
    
    begin
      error_or_nil = delegate.send_message(msg.id, from, to, subject, body)
      msg.send_succeeed app, channel
    rescue => e
      msg.send_failed app, channel, e
    else
      if !error_or_nil.nil?
        msg.send_failed app, channel, error_or_nil
      end
    end
  end
  
  def to_s
    "<SendXmppMessageJob:#{@message_id}>"
  end

end
