require 'net/smtp'

class SendSmtpMessageJob < SendMessageJob
  def managed_perform
    channel_relative_id = "<#{@msg.guid}@message_id.nuntium>"
    references = channel_relative_id
    @msg.custom_attributes.each do |key, value|
      next unless key.start_with?('references_')
      references += ", <#{value}@#{key[11 .. -1]}.nuntium>"
    end

msgstr = <<-END_OF_MESSAGE
From: #{@msg.from.without_protocol}
To: #{@msg.to.without_protocol}
Subject: #{@msg.subject}
Date: #{@msg.timestamp}
Message-Id: #{channel_relative_id}
References: #{references}

#{@msg.body}
END_OF_MESSAGE
    msgstr.strip!

    smtp = Net::SMTP.new(@config[:host], @config[:port].to_i)
    if (@config[:use_ssl].to_b)
      smtp.enable_tls
    end

    begin
      if @config[:user].present?
        smtp.start('localhost.localdomain', @config[:user], @config[:password])
      else
        smtp.start('localhost.localdomain')
      end
    rescue Net::SMTPAuthenticationError => ex
      raise PermanentException.new(ex)
    else
      begin
        smtp.send_message msgstr, @msg.from.without_protocol, @msg.to.without_protocol
        @msg.send_succeeed @account, @channel, channel_relative_id
      ensure
        smtp.finish
      end
    end
  end

  def to_s
    "<SendSmtpMessageJob:#{@message_id}>"
  end

end
