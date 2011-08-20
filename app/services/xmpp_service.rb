require 'blather/client/dsl'

class XmppService < Service
  include Blather::DSL

  PrefetchCount = 5

  def initialize(channel)
    @channel = channel
    @mq = MQ.new
    @mq.prefetch PrefetchCount
  end

  def start
    setup @channel.jid, @channel.password, @channel.server, @channel.port
    when_ready do
      Rails.logger.info "Connected to #{@channel.jid}"
      self.channel_connected = true

      set_status :chat, @channel.status if @channel.status.present?

      subscribe_queue
      receive_chats
      receive_errors
      receive_subscriptions
      handle_disconnections
    end
    client.run
  end

  def stop
    client.close
    @mq.close
    self.channel_connected = false
    EM.stop_event_loop
  end

  def receive_chats
    message :chat?, :body do |msg|
      at = AtMessage.new
      at.channel_relative_id = msg.id
      at.from = msg.from.stripped.to_s.with_protocol 'xmpp'
      at.to = msg.to.stripped.to_s.with_protocol 'xmpp'
      at.subject = msg.subject
      at.body = msg.body

      @channel.route_at at
    end
  end

  def receive_errors
    message :error? do |msg|
      ao = AoMessage.find_by_id msg.id
      if ao
        ao.state = 'failed'
        ao.save!

        @channel.logger.exception_in_channel_and_ao_message @channel, ao, "Code #{msg.error_code} - #{msg.error_type}"
      else
        Rails.logger.debug "Received error message: #{msg}"
      end
    end
  end

  def receive_subscriptions
    subscription :request? do |s|
      @channel.logger.info :message => "Accepting subscription from #{s.from}", :application_id => @channel.application_id, :channel_id => @channel.id

      write_to_stream s.approve!
    end
  end

  def handle_disconnections
    disconnected do
      Rails.logger.info "Disconnected, trying to reconnect..."
      self.channel_connected = false

      client.connect
    end
  end

  def send_message(id, from, to, subject, body)
    Rails.logger.debug "Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"

    msg = Blather::Stanza::Message.new
    msg.id = id
    msg.to = to
    if body.empty?
      msg.body = subject
    else
      msg.subject = subject
      msg.body = body
    end
    msg.type = :chat

    write_to_stream msg
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

  def channel_connected=(value)
    @channel.reload
    @channel.connected = value
    @channel.save!
  end
end
