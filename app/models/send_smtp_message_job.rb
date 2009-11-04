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
From: #{msg.from_without_protocol}
To: #{msg.to_without_protocol}
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
    smtp.start('localhost.localdomain', config[:user], config[:password])
    smtp.send_message msgstr, msg.from_without_protocol, msg.to_without_protocol
    smtp.finish
    
    AOMessage.update_all("state = 'delivered', tries = tries + 1", ['id = ?', msg.id])
  end
end