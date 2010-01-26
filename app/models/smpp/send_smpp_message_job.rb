require 'drb'

class SendSmppMessageJob
  attr_accessor :application_id, :channel_id, :message_id

  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end
  
  def perform  
    # fetch process associated with this channel
    @d_rb_process = DRbProcess.find_by_channel_id @channel_id
    if @d_rb_process.nil?
      RAILS_DEFAULT_LOGGER.error "Couldn't find registered DRb service for channel with id #{@channel_id}."
      return :error_finding_drb_service
    end
    
    channel = Channel.find @channel_id
    msg = AOMessage.find @message_id
    
    from = msg.from.without_protocol
    to = msg.to.without_protocol
    sms = msg.subject_and_body
    
    begin
      # start DRb service (required to talk to other services)
      DRb.start_service if DRb.thread == nil
      @smpp_gw = DRbObject.new nil, @d_rb_process.uri
  
      RAILS_DEFAULT_LOGGER.debug "Sending AOMessage with id #{@message_id} through SMPP channel with id #{@channel_id}."
      # try to send it through SMPP connection
      success = @smpp_gw.send_message(from, to, sms)
    rescue => e
      ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
      raise
    else
      # increase one try
      msg.tries += 1
      if success
        msg.state = 'delivered'
        msg.save    
      else
        msg.save
        ApplicationLogger.exception_in_channel_and_ao_message channel, msg, e
        raise
      end
      ApplicationLogger.message_channeled msg, channel
    end
  end
  
  def to_s
    "<SendSmppMessageJob:#{@message_id}>"
  end
  
end
