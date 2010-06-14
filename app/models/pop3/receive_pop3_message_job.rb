require 'net/pop'
require 'tmail'

class ReceivePop3MessageJob
  attr_accessor :account_id, :channel_id

  include CronTask::QuotedTask

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
  end
  
  def perform
    account = Account.find @account_id
    @channel = account.find_channel @channel_id
    config = @channel.configuration
    
    pop = Net::POP3.new(config[:host], config[:port].to_i)
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if config[:use_ssl].to_b
    
    begin
      pop.start(config[:user], config[:password])
    rescue Net::POPAuthenticationError => ex
      @channel.alert "#{ex}"
    
      @channel.enabled = false
      @channel.save!
      return
    end
    
    pop.each_mail do |mail|
      tmail = TMail::Mail.parse(mail.pop)
      tmail_body = get_body tmail
      
      tmail.to.each do |receiver|
        msg = ATMessage.new
        msg.from = "mailto://#{tmail.from[0]}"
        msg.to = "mailto://#{receiver}"
        msg.subject = tmail.subject
        msg.body = tmail_body
        msg.channel_relative_id = tmail.message_id
        msg.timestamp = tmail.date
        
        account.route_at msg, @channel
      end
      
      mail.delete
      break if not has_quota?
    end
    
    pop.finish
  rescue => ex
    AccountLogger.exception_in_channel @channel, ex if @channel
  end
  
  def get_body(tmail)
    # Not multipart? Return body as is.
    return tmail.body if !tmail.multipart?
    
    # Return text/plain part.
    tmail.parts.each do |part|
      return part.body if part.content_type == 'text/plain'
    end
    
    # Or body if not found
    return tmail.body
  end
end
