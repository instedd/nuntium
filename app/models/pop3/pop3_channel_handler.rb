require 'net/pop'

class Pop3ChannelHandler < ChannelHandler
  def handle(msg)
    # TODO: can't handle messages
  end
  
  def check_valid
    @channel.errors.add(:host, "can't be blank") if
        @channel.configuration[:host].blank?
        
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank")
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end
  
    @channel.errors.add(:user, "can't be blank") if
        @channel.configuration[:user].blank?
        
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].blank?
  end
  
  def check_valid_in_ui
    config = @channel.configuration
    
    pop = Net::POP3.new(config[:host], config[:port].to_i)
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if config[:use_ssl] == '1'
    
    begin
      pop.start(config[:user], config[:password])
      pop.finish
    rescue => e
      @channel.errors.add_to_base(e.message)
    end
  end
  
  def info
    c = @channel.configuration
    "#{c[:user]}@#{c[:host]}:#{c[:port]}"
  end

  def on_enable
    @channel.create_task('pop3-receive', POP3_RECEIVE_INTERVAL, ReceivePop3MessageJob.new(@channel.application_id, @channel.id))
  end
  
  def on_disable
    @channel.drop_task('pop3-receive')
  end
  
  def on_destroy
    on_disable  
  end
  
end