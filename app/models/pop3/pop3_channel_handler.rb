require 'net/pop'

class Pop3ChannelHandler < ChannelHandler
  def self.title
    "POP3"
  end

  def check_valid
    check_config_not_blank :host, :user, :password
    check_config_port
  end

  def check_valid_in_ui
    config = @channel.configuration

    pop = Net::POP3.new(config[:host], config[:port].to_i)
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if config[:use_ssl].to_b

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
    @channel.create_task('pop3-receive', POP3_RECEIVE_INTERVAL, ReceivePop3MessageJob.new(@channel.account_id, @channel.id))
  end

  def on_disable
    @channel.drop_task('pop3-receive')
  end

  def on_pause
    on_disable
  end

  def on_resume
    on_enable
  end

  def on_destroy
    on_disable
  end

end
