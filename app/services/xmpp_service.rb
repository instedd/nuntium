require 'xmpp4r/client'
require 'xmpp4r/roster'

class XmppService < Service

  include Jabber

  PrefetchCount = 5

  def initialize(channel)
    @channel = channel
    @mq = MQ.new
    @mq.prefetch PrefetchCount
  end

  def start
    if !connect
      # Give some time to flush EM events
      EM.add_timer(5) { stop }
      return
    end

    handle_exceptions
    receive_messages
    receive_subscriptions
    subscribe_queue
    keep_me_alive
  end

  def connect
    begin
      @client = Client.new(@channel.handler.jid)
      @client.connect @channel.handler.server, @channel.configuration[:port]
      @client.auth @channel.configuration[:password]

      presence = Presence.new.set_show(:chat)
      presence.set_status @channel.configuration[:status] if @channel.configuration[:status].present?
      @client.send presence
      true
    rescue ClientAuthenticationFailure => ex
      alert_msg = "#{ex} #{ex.backtrace}"

      @channel.alert alert_msg

      @channel.enabled = false
      @channel.save!

      false
    rescue Exception => ex
      logger.error ex
      false
    end
  end

  def send_message(id, from, to, subject, body)
    Rails.logger.debug "Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"

    msg = Message.new
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
    @mq.close
    EM.stop_event_loop
  end

  def receive_messages
    @client.add_message_callback do |msg|
      Rails.logger.debug "Receiving message #{msg}"

      # Sometimes a nil msg arrives...
      next unless msg

      if msg.type == :error
        ao = AOMessage.find_by_id msg.id
        if ao
          ao.state = 'failed'
          ao.save!

          @channel.logger.exception_in_channel_and_ao_message @channel, ao, "Code #{msg.error.code} - #{msg.error.text}"
        else
          Rails.logger.debug "Received error message: #{msg}"
        end
        next
      end

      # The body might be empty when receiving "composing" messages
      next unless msg.body.present?

      at = ATMessage.new
      at.channel_relative_id = msg.id
      at.from = msg.from.bare.to_s.with_protocol 'xmpp'
      at.to = msg.to.bare.to_s.with_protocol 'xmpp'
      at.subject = msg.subject
      at.body = msg.body

      @channel.route_at at
    end
  end

  def receive_subscriptions
    @roster = Roster::Helper.new(@client)
    @roster.add_subscription_request_callback do |item, pres|
      @channel.logger.info :message => "Accepting subscription from #{pres.from}", :application_id => @channel.application_id, :channel_id => @channel.id

      # we accept everyone
      @roster.accept_subscription(pres.from)

      # Now it's our turn to send a subscription request
      presence = Presence.new.set_type(:subscribe).set_to(pres.from)
      @client.send presence
    end
  end

  def subscribe_queue
    Rails.logger.info "Subscribing to message queue"

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      Rails.logger.debug "Executing job #{job}"
      begin
        job.perform self
        header.ack
      rescue Exception => e
        Rails.logger.error "Error when performing job. Exception: #{e.class} #{e}"
        unsubscribe_temporarily
      end
    end

    @subscribed = true
  end

  def unsubscribe_temporarily
    if @subscribed
      unsubscribe_queue
      EM.add_timer(5) { subscribe_queue }
    end
  end


  def unsubscribe_queue
    Rails.logger.info "Unsubscribing from message queue"

    @mq = Queues.reconnect(@mq)
    @mq.prefetch PrefetchCount

    @subscribed = false
  end

  def handle_exceptions
    @client.on_exception do |ex|
      # TODO do something else...
      Rails.logger.error "#{ex}"
      if @client.is_disconnected?
        if !connect
          stop
        end
      end
    end
  end

  def keep_me_alive
    EM.add_periodic_timer(1) do
      # Nothing
    end
  end

end
