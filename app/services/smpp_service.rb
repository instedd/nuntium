class SmppService < Service

  def initialize(channel)
    super nil
    @channel = channel
  end

  def start
    @gateway = SmppGateway.new @channel
    @gateway.start
  end
  
  def stop
    @gateway.stop
    EM.stop_event_loop
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
    @config = {
      :host => channel.configuration[:host],
      :port => channel.configuration[:port],
      :system_id => channel.configuration[:user],
      :password => channel.configuration[:password],
      :system_type => channel.configuration[:system_type],
      :interface_version => 52,
      :source_ton  => channel.configuration[:source_ton].to_i,
      :source_npi => channel.configuration[:source_npi].to_i,
      :destination_ton => channel.configuration[:destination_ton].to_i,
      :destination_npi => channel.configuration[:destination_npi].to_i,
      :source_address_range => '',
      :destination_address_range => '',
      :enquire_link_delay_secs => 10
    }
    @pending_headers = {}
    @is_running = false
  end
  
  def start
    connect
    @is_running = true 
  end
  
  def connect
    Rails.logger.info "Connecting to SMSC"
  
    @transceiver = EM.connect(@config[:host], @config[:port], MyTransceiver, @config, self)
  end
  
  def stop
    Rails.logger.info "Closing SMPP connection"
  
    @is_running = false
    @transceiver.close_connection
    unsubscribe_queue
  end
  
  def bound(transceiver)
    Rails.logger.info "Delegate: transceiver bound"
    
    subscribe_queue
  end
  
  def message_accepted(transceiver, mt_message_id, pdu)
    super
    send_ack mt_message_id
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    case pdu.command_status
    
    # Queue full
    when Smpp::Pdu::Base::ESME_RMSGQFUL,
         Smpp::Pdu::Base::ESME_RTHROTTLED
      Rails.logger.info "Received ESME_RMSGQFUL or ESME_RHTORTTLED (#{pdu.command_status})"  

      # Stop sending messages for a while      
      unsubscribe_queue
      EM.add_timer(5) { subscribe_queue; MQ.recover(true) }
      
    # Message source or address not valid
    when Smpp::Pdu::Base::ESME_RINVSRCADR,
         Smpp::Pdu::Base::ESME_RINVDSTADR
      super
      send_ack mt_message_id
      
    # Disable channel and alert
    else
      alert_msg = "Received command status #{pdu.command_status} in smpp channel #{@channel.name} (#{@channel.id})"
    
      Rails.logger.warn alert_msg 
      @channel.application.alert alert_msg
    
      @channel.enabled = false
      @channel.save!
      
      stop
    end
  end

  def unbound(transceiver)
    Rails.logger.info "Delegate: transceiver unbound"
    
    unsubscribe_queue
    
    if @is_running
      Rails.logger.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
      connect if @is_running
    end
  end
  
  private
  
  def subscribe_queue
    Rails.logger.info "Subscribing to message queue"
    
    Queues.subscribe_ao(@channel) do |header, job|
      begin
        job.perform self
        @pending_headers[job.message_id] = header
      rescue Exception => e
        Rails.logger.error "Error when performing job. Body was: '#{body}'. Exception: #{e.class} #{e}"
      end
      
      sleep_time
    end
  end
  
  def unsubscribe_queue
    Rails.logger.info "Unsubscribing from message queue"
  
    Queues.unsubscribe_ao @channel
  end
  
  def send_ack(message_id)
    header = @pending_headers.delete(message_id)
    if header
      header.ack
    else
      Rails.logger.error "Pending header not found for message id: #{mt_message_id}"
    end
  end
  
  def sleep_time
    if @channel.throttle and @channel.throttle > 0
      sleep(60.0 / @channel.throttle)
    end
  end
  
end
