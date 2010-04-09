require 'net/smtp'

class SendSmtpMessageJob < SendMessageJob
  def managed_perform
    channel_relative_id = "<#{@msg.guid}@nuntium.instedd.org>"
    
msgstr = <<-END_OF_MESSAGE
From: #{@msg.from.without_protocol}
To: #{@msg.to.without_protocol}
Subject: #{@msg.subject}
Date: #{@msg.timestamp}
Message-Id: #{channel_relative_id}

#{@msg.body}
END_OF_MESSAGE
    msgstr.strip!
    
    smtp = Net::SMTP.new(@config[:host], @config[:port].to_i)
    if (@config[:use_ssl] == '1')
      smtp.enable_tls
    end
    
    begin
      smtp.start('localhost.localdomain', @config[:user], @config[:password])
    rescue => e
      @msg.send_failed @app, @channel, e
    else
      begin
        smtp.send_message msgstr, @msg.from.without_protocol, @msg.to.without_protocol
      rescue => e
        @msg.send_failed @app, @channel, e
      else
        @msg.send_succeeed @app, @channel, channel_relative_id
      ensure
        smtp.finish
      end
    end
  end
  
  def to_s
    "<SendSmtpMessageJob:#{@message_id}>"
  end
  
end
