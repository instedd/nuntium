require 'net/smtp'

class SendSmtpMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    config = channel.configuration
    
msgstr = <<-END_OF_MESSAGE
From: #{msg.from.without_protocol}
To: #{msg.to.without_protocol}
Subject: #{msg.subject}
Date: #{msg.timestamp}
Message-Id: #{msg.guid}

#{msg.body}
END_OF_MESSAGE
    msgstr.strip!
    
    smtp = Net::SMTP.new(config[:host], config[:port].to_i)
    if (config[:use_ssl] == '1')
      smtp.enable_tls
    end
    
    begin
      smtp.start('localhost.localdomain', config[:user], config[:password])
    rescue => e
      ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
      raise
    else
      begin
        smtp.send_message msgstr, msg.from.without_protocol, msg.to.without_protocol
      rescue => e
        ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
        AOMessage.update_all("tries = tries + 1", ['id = ?', msg.id])  
        raise
      else
        AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])  
      end
    
      smtp.finish
    end
  end
end