class ChannelService < Service
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
    channel_class.active.each do |channel|
      start_channel channel
    end
  end

  def subscribe_to_notifications
    Queues.subscribe_notifications(kind, kind, @notifications_session) do |header, job|
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
    connection = connection_class.new channel
    if connection.start
      @connections[channel.id] = connection
    end
  end

  def stop_channel(id)
    connection = @connections.delete id
    connection.stop if connection
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

  def identifier
    self.class.name =~ /(.*)Service/
    $1
  end

  def kind
    identifier.underscore
  end

  def channel_class
    "#{identifier}Channel".constantize
  end

  def connection_class
    "#{identifier}Connection".constantize
  end
end
