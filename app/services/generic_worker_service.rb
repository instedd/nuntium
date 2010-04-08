class GenericWorkerService < Service

  def start
    @sessions = {}
    Channel.find_each(
      :conditions => ['enabled = ? AND (direction = ? OR direction = ?)', 
        true, 
        Channel::Outgoing, Channel::Both]) do |chan|
      next unless chan.handler.publishes_to_ao_queue?
      
      mq = MQ.new
      @sessions[chan] = mq
      Queues.subscribe_ao chan, mq do |header, job|
        job.perform
      end
    end
    
    @notifications_session = MQ.new
    Queues.subscribe_notifications @notifications_session do |header, job|
    end
  end
  
  def stop
  end

end
