class SmtpChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendSmtpMessageJob.new(@channel.application_id, @channel.id, msg.id)
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
  
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].nil? || @channel.configuration[:user].chomp.empty?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
  end
end