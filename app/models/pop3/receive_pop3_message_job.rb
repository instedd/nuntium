require 'net/pop'
require 'tmail'

class ReceivePop3MessageJob
  attr_accessor :application_id, :channel_id

  include CronTask::QuotedTask

  def initialize(application_id, channel_id)
    @application_id = application_id
    @channel_id = channel_id
  end
  
  def perform
    application = Application.find @application_id
    channel = Channel.find @channel_id
    config = channel.configuration
    
    pop = Net::POP3.new(config[:host], config[:port].to_i)
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if config[:use_ssl] == '1'
    
    begin
      pop.start(config[:user], config[:password])
    rescue => e
      ApplicationLogger.exception_in_channel channel, e
      raise
    end
    
    logger = ApplicationLogger.new(@application_id)
    
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
        
        application.accept msg, channel
      end
      
      mail.delete
      break if not has_quota?
    end
    
    pop.finish

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
  
  # Enqueues jobs of this class for each channel
  # found in the application
  def self.enqueue_for_all_channels
    Channel.find_each(:conditions => "kind = 'pop3'") do |chan|
      job = ReceivePop3MessageJob.new(chan.application_id, chan.id)
      Delayed::Job.enqueue job
    end
  end
end
