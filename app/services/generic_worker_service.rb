class GenericWorkerService < Service

  PrefetchCount = 5
  
  def initialize(controller = nil, suspension_time = 5 * 60)
    super(controller)
    @suspension_time = suspension_time
  end

  def start
    @sessions = {}
    
    Channel.find_each(
      :conditions => ['enabled = ? AND (direction = ? OR direction = ?)', 
        true, 
        Channel::Outgoing, Channel::Both]) do |chan|
      next unless chan.handler.class < GenericChannelHandler
      
      mq = MQ.new
      mq.prefetch PrefetchCount
      @sessions[chan.id] = mq
      
      puts "start: #{@sessions.keys.inspect}"

      Queues.subscribe_ao chan, mq do |header, job|
        begin
          job.perform
          header.ack
        rescue PermanentException => ex
          chan.enabled = false
          chan.save!
        rescue TemporaryException => ex
          Queues.publish_notification ChannelUnsubscriptionJob.new(chan.id), @notifications_session
          EM.add_timer(@suspension_time) do 
            Queues.publish_notification ChannelSubscriptionJob.new(chan.id), @notifications_session            
          end
        end
      end
    end
    
    @notifications_session = MQ.new
    Queues.subscribe_notifications @notifications_session do |header, job|
      puts "consuming #{job}"
      job.perform self
    end
  end
  
  def subscribe_to_channel(channel_id)
  end
  
  def unsubscribe_from_channel(channel_id)
    puts "uns: #{@sessions.keys}"
    @sessions.delete(channel_id).close
  end
  
  def stop
  end

end
