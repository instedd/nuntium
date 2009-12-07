class DtacChannelHandler < ChannelHandler
  def handle(msg)
    Delayed::Job.enqueue SendDtacMessageJob.new(@channel.application_id, @channel.id, msg.id)
  end
  
  def check_valid
    # TODO: Validate
    true
  end
  
  def info
    # TODO: Return valid info on the channel
    'Info on this dtac channel'
  end
end
