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
    channel = Channel.find @channel_id
    config = channel.configuration
    
    pop = Net::POP3.new(config[:host], config[:port].to_i)
    if (config[:use_ssl] == '1')
      pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    end
    
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
        msg.application_id = @application_id
        msg.from = 'mailto://' + tmail.from[0]
        msg.to = 'mailto://' + receiver
        msg.subject = tmail.subject
        msg.body = tmail_body
        msg.channel_relative_id = tmail.message_id
        msg.timestamp = tmail.date
        msg.state = 'queued'
        msg.save
        
        logger.at_message_received_via_channel msg, channel
      end
      
      mail.delete
      break if not has_quota?
    end
    
    pop.finish

  end
  
  def get_body(tmail)
    # Not multipart? Return body as is.
    if !tmail.multipart?
      return tmail.body
    end
    
    # Return text/plain part.
    tmail.parts.each do |part|
      if part.content_type == 'text/plain'
        return part.body
      end
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
