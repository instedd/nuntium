require 'xmpp4r/client'

class XmppService < Service

  include Jabber

  PrefetchCount = 5

  def initialize(channel)
    @channel = channel
    c = @channel.configuration
    
    jid_str = "#{c[:user]}@#{c[:domain]}"
    jid_str << "/#{c[:resource]}" unless c[:resource].blank?
    @jid = JID::new(jid_str)
    
    @mq = MQ.new
    @mq.prefetch PrefetchCount 
  end

  def start
    @client = Client::new(@jid)
    
    begin
      if @channel.configuration[:server].blank?
        @client.connect
      else
        @client.connect @channel.configuration[:server]
      end
      @client.auth @channel.configuration[:password]
    rescue => ex
      alert_msg = ex.to_s
      
      Rails.logger.debug "Can't connect: #{alert_msg}"
      @channel.alert alert_msg
    
      @channel.enabled = false
      @channel.save!
      
      EM.stop_event_loop
      return
    end
    
    receive_messages
    subscribe_queue
    keep_me_alive
  end
  
  def send_message(id, from, to, subject, body)
    Rails.logger.debug "Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"
     
    msg = Message::new
    msg.id = id
    #msg.from = from
    msg.to = to
    if body.empty?
      msg.body = subject
    else
      msg.subject = subject
      msg.body = body
    end
    msg.type = :chat
    
    @client.send msg
  end
  
  def stop
    @client.close
    EM.stop_event_loop
  end
  
  def receive_messages
    @client.add_message_callback do |msg|
      Rails.logger.debug "Receiving message #{msg}"
      
      if msg.type == :error
        ao = AOMessage.find_by_id msg.id
        if ao
          ao.state = 'failed'
          ao.save!
          @channel.application.logger.exception_in_channel_and_ao_message @channel, ao, msg.error.to_s
        else
          Rails.logger.debug "Received error message: #{msg}"
        end
        next
      end
      
      at = ATMessage.new
      at.channel_relative_id = msg.id
      at.from = msg.from.to_s.with_protocol 'xmpp'
      at.to = msg.to.to_s.with_protocol 'xmpp'
      at.subject = msg.subject
      at.body = msg.body
      @channel.accept at
    end
  end
  
  def subscribe_queue
    Queues.subscribe_ao(@channel, @mq) do |header, job|
      Rails.logger.debug "Executing job #{job}"
      begin
        job.perform self
        header.ack
      rescue Exception => e
        Rails.logger.error "Error when performing job. Exception: #{e.class} #{e}"
      end
    end
  end
  
  def keep_me_alive
    EM.add_periodic_timer(1) do
      # Nothing
    end
  end

end
