require 'net/smtp'

class SmtpChannelHandler < ChannelHandler
  include GenericChannelHandler

  def self.title
    "SMTP"
  end

  def check_valid
    check_config_not_blank :host
    check_config_port
  end

  def check_valid_in_ui
    config = @channel.configuration

    smtp = Net::SMTP.new(config[:host], config[:port].to_i)
    if (config[:use_ssl].to_b)
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
