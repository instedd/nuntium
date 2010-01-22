class SmppChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendSmppMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    @channel.errors.add(:host, "can't be blank") if
        @channel.configuration[:host].nil? || @channel.configuration[:host].chomp.empty?
        
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank")
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end

    if @channel.configuration[:ton].nil?
      @channel.errors.add(:ton, "can't be blank")
    else
      ton_num = @channel.configuration[:ton].to_i
      if ton_num < 0 || ton_num > 7
        @channel.errors.add(:ton, "must be a number between 0 and 7")
      end
    end

    if @channel.configuration[:npi].nil?
      @channel.errors.add(:npi, "can't be blank")
    else
      npi_num = @channel.configuration[:npi].to_i
      if npi_num < 0 || npi_num > 7
        @channel.errors.add(:npi, "must be a number between 0 and 7")
      end
    end  
  
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
  end
  
  def check_valid_in_ui
    config = @channel.configuration
    
    # what kind of validation should we put here?
    # what if the smpp connection require a vpn?

  end
  
  def info
    c = @channel.configuration
    "#{c[:user]}@#{c[:host]}:#{c[:port]}"
  end
end