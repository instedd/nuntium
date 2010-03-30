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
    @is_running = false
  end
  
  def start
    connect
    @is_running = true 
  end
  
  def connect
    Rails.logger.info "Connecting to SMSC"
  
    @transceiver = EM.connect(
      @config[:host],
      @config[:port],
      MyTransceiver, 
      @config, 
      self    # delegate that will receive callbacks on MOs and DRs and other events
    )
  end
  
  def stop
    Rails.logger.info "Closing SMPP connection"
  
    @is_running = false
    @transceiver.close_connection
  end

  def bound(transceiver)
    Rails.logger.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    Rails.logger.info "Delegate: transceiver unbound"
    
    if @is_running
      Rails.logger.warn "Disconnected. Reconnecting in 5 seconds..."
      sleep 5
      connect if @is_running
    end
  end
  
end
