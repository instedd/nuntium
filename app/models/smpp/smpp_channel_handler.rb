class SmppChannelHandler < ServiceChannelHandler
  def job_class
    SendSmppMessageJob
  end
  
  def service_name
    'smpp_daemon'
  end
  
  def check_valid
    check_config_not_blank :host, :system_type
    
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank")
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end
    
    [:source_ton, :source_npi, :destination_ton, :destination_npi].each do |sym|
      if @channel.configuration[sym].nil?
        @channel.errors.add(sym, "can't be blank")
      else
        s = @channel.configuration[sym].to_i
        if s < 0 || s > 7
          @channel.errors.add(sym, "must be a number between 0 and 7")
        end
      end
    end
  
    check_config_not_blank :user, :password, :default_mo_encoding, :mt_encodings, :mt_csms_method
  end
  
  def check_valid_in_ui
    config = @channel.configuration
    
    # what kind of validation should we put here?
    # what if the smpp connection require a vpn?

  end
  
  def info
    c = @channel.configuration
    s = "#{c[:user]}@#{c[:host]}:#{c[:port]}"
    s << " (#{@channel.throttle}/min)" if @channel.throttle.present? and @channel.throttle != 0
    s
  end
end
