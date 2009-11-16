require 'net/pop'
require 'tmail'
require 'guid'

class ReceivePop3MessageJob
  attr_accessor :application_id, :channel_id

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
    
    pop.start(config[:user], config[:password])
    pop.each_mail do |mail|
      tmail = TMail::Mail.parse(mail.pop)
      tmail_body = get_body tmail
      tmail_guid = tmail.message_id.nil? ? Guid.new.to_s : tmail.message_id
      
      tmail.to.each do |receiver|
        msg = ATMessage.new
        msg.application_id = @application_id
        msg.from = 'mailto://' + tmail.from[0]
        msg.to = 'mailto://' + receiver
        msg.subject = tmail.subject
        msg.body = tmail_body
        msg.guid = tmail_guid
        msg.timestamp = tmail.date
        msg.state = 'queued'
        msg.save
      end
      
      mail.delete
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
