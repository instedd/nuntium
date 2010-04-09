class GenericWorkerService < Service

  def start
    @sessions = {}
    
    Channel.find_each(
      :conditions => ['enabled = ? AND (direction = ? OR direction = ?)', 
        true, 
        Channel::Outgoing, Channel::Both]) do |chan|
      next unless chan.handler.class < GenericChannelHandler
      
      mq = MQ.new
      @sessions[chan.id] = mq

      Queues.subscribe_ao chan, mq do |header, job|
        begin
          job.perform
        rescue PermanentException => ex
          begin
            chan.enabled = false
            chan.save!
          rescue Exception => ex
            puts ex
          end
        end
      end
    end
    
    @notifications_session = MQ.new
    Queues.subscribe_notifications @notifications_session do |header, job|
    end
  end
  
  def stop
  end

end
