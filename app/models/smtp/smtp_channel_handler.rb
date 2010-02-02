require 'net/smtp'

class SmtpChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendSmtpMessageJob.new(@channel.application_id, @channel.id, msg.id)
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
    
    smtp = Net::SMTP.new(config[:host], config[:port].to_i)
    if (config[:use_ssl] == '1')
      smtp.enable_tls
    end
    
    begin
      smtp.start('localhost.localdomain', config[:user], config[:password])
      smtp.finish
    rescue => e
      @channel.errors.add_to_base(e.message)
    end
  end
  
  def info
    c = @channel.configuration
    "#{c[:user]}@#{c[:host]}:#{c[:port]}"
  end
end