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
    channel_relative_id = "<#{msg.guid}@nuntium.instedd.org>"
    
msgstr = <<-END_OF_MESSAGE
From: #{msg.from.without_protocol}
To: #{msg.to.without_protocol}
Subject: #{msg.subject}
Date: #{msg.timestamp}
Message-Id: #{channel_relative_id}

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
        msg.tries += 1
        msg.channel_relative_id = channel_relative_id
        msg.save
        ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
        raise
      else
        msg.state = 'delivered'
        msg.tries += 1
        msg.channel_relative_id = channel_relative_id
        msg.save
      end
      ApplicationLogger.message_channeled msg, channel
      smtp.finish
    end
  end
  
  def to_s
    "<SendSmtpMessageJob:#{@message_id}>"
  end
  
end