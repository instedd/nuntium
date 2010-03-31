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
  end
  
  def bound(transceiver)
    Rails.logger.info "Delegate: transceiver bound"
    
    Queues.subscribe_ao(@channel) do |header, job|
      Rails.logger.info "JOB: #{job}"
    
      begin
        job.perform self
        @pending_headers[job.message_id] = header
      rescue Exception => e
        Rails.logger.error "Error when performing job. Body was: '#{body}'. Exception: #{e.class} #{e}"
      end
      
      sleep_time
    end
  end
  
  def message_accepted(transceiver, mt_message_id, pdu)
    super
    header = @pending_headers.delete(mt_message_id)
    if header
      header.ack
    else
      Rails.logger.error "Pending header not found for message id: #{mt_message_id}"
    end
  end

  def unbound(transceiver)
    Rails.logger.info "Delegate: transceiver unbound"
    
    Queues.unsubscribe_ao @channel
    
    if @is_running
      Rails.logger.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
      connect if @is_running
    end
  end
  
  private
  
  def sleep_time
    if @channel.throttle and @channel.throttle > 0
      sleep(60.0 / @channel.throttle)
    end
  end
  
end
