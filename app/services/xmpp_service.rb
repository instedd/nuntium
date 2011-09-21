require 'blather/client/dsl'

class XmppService < Service
  def initialize
    @notifications_session = MQ.new
    @connections = {}
  end

  def start
    start_connections
    subscribe_to_notifications
    notify_connection_status_loop
  end

  def start_connections
    XmppChannel.active.each do |channel|
      start_channel channel
    end
  end

  def subscribe_to_notifications
    Queues.subscribe_notifications('xmpp', 'xmpp', @notifications_session) do |header, job|
      job.perform self
    end
  end

  def notify_connection_status_loop
    EM.add_periodic_timer 1.minute do
      @connections.each_value &:notify_connection_status
    end
  end

  def start_channel(channel)
    channel = Channel.find channel unless channel.is_a? Channel
    connection = XmppConnection.new channel
    @connections[channel.id] = connection
    connection.start
  end

  def stop_channel(id)
    connection = @connections.delete id
    connection.stop
  end

  def restart_channel(id)
    stop_channel id
    start_channel id
  end

  def stop
    stop_connections
    EM.stop_event_loop
  end

  def stop_connections
    @connections.each &:stop
  end
end

class XmppConnection
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
    @mq.close
    client.close
    self.channel_connected = false
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
        Rails.logger.debug "[#{@channel.name}] Received error message: #{msg}"
      end
    end
  end

  def receive_subscriptions
    subscription :request? do |s|
      @channel.logger.info :message => "[#{@channel.name}] Accepting subscription from #{s.from}", :application_id => @channel.application_id, :channel_id => @channel.id

      write_to_stream s.approve!
    end
  end

  def handle_disconnections
    disconnected do
      self.channel_connected = false

      @channel.reload

      if @channel.active?
        Rails.logger.info "[#{@channel.name}] Disconnected, trying to reconnect..."

        client.connect
      end

      true
    end
  end

  def send_message(id, from, to, subject, body)
    Rails.logger.debug "[#{@channel.name}] Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"

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
    Rails.logger.info "[#{@channel.name}] Subscribing to message queue"

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      Rails.logger.debug "[#{@channel.name}] Executing job #{job}"
      begin
        job.perform self
        header.ack
      rescue Exception => e
        Rails.logger.error "[#{@channel.name}] Error when performing job. Exception: #{e.class} #{e}"
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
    Rails.logger.info "[#{@channel.name}] Unsubscribing from message queue"

    @mq = Queues.reconnect(@mq)
    @mq.prefetch PrefetchCount

    @subscribed = false
  end

  def channel_connected=(value)
    @connected = value
    @channel.connected = value
  end

  def notify_connection_status
    @channel.connected = @connected
  end
end
