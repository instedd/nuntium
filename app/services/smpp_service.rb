require 'smpp'

class SmppService < ChannelService
end

class SmppConnection
  def initialize(channel)
    @channel = channel
  end

  def start
    @gateway = SmppGateway.new @channel
    @gateway.start
  end

  def notify_connection_status
    @gateway.notify_connection_status
  end

  def stop
    @gateway.stop
  end
end

# Fix to keep the enquire link timer
class MyTransceiver < Smpp::Transceiver
  def post_init
    @timer = super
  end
  def unbind
    super
    @timer.cancel
  end
end

class SmppGateway < SmppTransceiverDelegate

  def initialize(channel)
    super nil, channel
    @prefetch_count = channel.max_unacknowledged_messages.to_i
    @prefetch_count = 5 if @prefetch_count <= 0

    @config = {
      :host => channel.host,
      :port => channel.port,
      :system_id => channel.user,
      :password => channel.password,
      :system_type => channel.system_type,
      :interface_version => 52,
      :source_ton  => channel.source_ton.to_i,
      :source_npi => channel.source_npi.to_i,
      :destination_ton => channel.destination_ton.to_i,
      :destination_npi => channel.destination_npi.to_i,
      :source_address_range => '',
      :destination_address_range => '',
      :enquire_link_delay_secs => 10
    }
    @pending_headers = {}
    @is_running = false
    @subscribed = false
    @mq = MQ.new
    @mq.prefetch @prefetch_count

    @suspension_codes = [Smpp::Pdu::Base::ESME_RMSGQFUL, Smpp::Pdu::Base::ESME_RTHROTTLED]
    @suspension_codes += channel.suspension_codes_as_array

    @rejection_codes = [Smpp::Pdu::Base::ESME_RINVSRCADR, Smpp::Pdu::Base::ESME_RINVDSTADR]
    @rejection_codes += channel.rejection_codes_as_array

    MQ.error { |err| Rails.logger.error err }
  end

  def start
    connect
    @is_running = true
  end

  def connect
    Rails.logger.info "[#{@channel.name}] Connecting to SMSC"

    @transceiver = EM.connect(@config[:host], @config[:port], MyTransceiver, @config, self)
  end

  def stop
    Rails.logger.info "[#{@channel.name}] Closing SMPP connection"

    self.channel_connected = false

    @is_running = false
    @transceiver.close_connection
    unsubscribe_queue
  end

  def bound(transceiver)
    Rails.logger.info "[#{@channel.name}] Delegate: transceiver bound"

    self.channel_connected = true

    subscribe_queue
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    super
    send_ack mt_message_id
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    case pdu.command_status

    # Queue full
    when *@suspension_codes
      Rails.logger.info "[#{@channel.name}] Received ESME_RMSGQFUL or ESME_RHTORTTLED (#{pdu.command_status})"
      unsubscribe_temporarily

    # Message source or address not valid
    when *@rejection_codes
      super
      send_ack mt_message_id

    # Disable channel and alert
    else
      alert_msg = "Received command status #{pdu.command_status} in smpp channel #{@channel.name} (#{@channel.id})"

      Rails.logger.warn alert_msg
      @channel.alert alert_msg

      @channel.enabled = false
      @channel.save!

      stop
    end
  end

  def unbound(transceiver)
    Rails.logger.info "[#{@channel.name}] Delegate: transceiver unbound"

    self.channel_connected = false

    @channel.reload

    if @is_running && @channel.active?
      unsubscribe_queue

      if @is_running
        Rails.logger.warn "[#{@channel.name}] Disconnected. Reconnecting in 5 seconds..."
        sleep 5
        connect if @is_running
      end
    end
  end

  def subscribe_queue
    Rails.logger.info "[#{@channel.name}] Subscribing to message queue"

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      Rails.logger.debug "[#{@channel.name}] Executing job #{job}"
      begin
        if job.perform(self)
          @pending_headers[job.message_id] = header
        else
          header.ack
        end
      rescue Exception => ex
        Rails.logger.info "[#{@channel.name}] Error when performing job. Exception: #{ex.class} #{ex}"
        reschedule job, header, ex
      end

      sleep_time
    end

    @subscribed = true
  end

  def unsubscribe_queue
    Rails.logger.info "[#{@channel.name}] Unsubscribing from message queue"

    @mq = Queues.reconnect(@mq)
    @mq.prefetch @prefetch_count

    @subscribed = false
  end

  def reschedule(job, header, ex)
    job.reschedule ex
  rescue => ex
    Rails.logger.info "[#{@channel.name}] Exception rescheduling #{job}: #{ex.class} #{ex} #{ex.backtrace}"
    unsubscribe_temporarily
  else
    header.ack
  end

  def unsubscribe_temporarily
    if @subscribed
      unsubscribe_queue
      EM.add_timer(5) { subscribe_queue }
    end
  end

  def send_ack(message_id)
    header = @pending_headers.delete(message_id)
    if header
      header.ack
    else
      Rails.logger.error "[#{@channel.name}] Pending header not found for message id: #{message_id}"
    end
  end

  def sleep_time
    if @channel.throttle and @channel.throttle > 0
      sleep(60.0 / @channel.throttle)
    end
  end

  def channel_connected=(value)
    @connected = value
    @channel.connected = value
  end

  def notify_connection_status
    @channel.connected = @connected
  end
end
