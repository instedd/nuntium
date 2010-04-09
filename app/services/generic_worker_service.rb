class GenericWorkerService < Service

  def start
    @sessions = {}
    
    Channel.all(
      :conditions => ['enabled = ? AND (direction = ? OR direction = ?)', 
        true, 
        Channel::Outgoing, Channel::Both]).each do |chan|
      next unless chan.handler.class < GenericChannelHandler
      
      mq = MQ.new
      @sessions[chan.id] = mq
      p "1. Channel size: #{Channel.all.size}"
      p "1. Application size: #{Application.all.size}"

      Queues.subscribe_ao chan, mq do |header, job|
        p "2. Channel size: #{Channel.all.size}"
        p "2. Application size: #{Application.all.size}"

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
