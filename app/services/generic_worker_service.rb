class GenericWorkerService < Service

  PrefetchCount = 5
  
  def initialize(controller = nil, suspension_time = 5 * 60)
    super(controller)
    @suspension_time = suspension_time
  end

  def start
    Rails.logger.info "Starting"
    MQ.error { |err| Rails.logger.error err }
  
    @sessions = {}
    
    Channel.find_each(
      :conditions => ['enabled = ? AND (direction = ? OR direction = ?)', 
        true, 
        Channel::Outgoing, Channel::Both]) do |chan|
      next unless chan.handler.class < GenericChannelHandler

      subscribe_to_channel chan
    end
    
    @notifications_session = MQ.new
    Queues.subscribe_notifications @notifications_session do |header, job|
      job.perform self
    end
  end
  
  def subscribe_to_channel(channel)
    channel = Channel.find_by_id channel unless channel.kind_of? Channel
    return unless channel.enabled
    return if @sessions.include? channel.id
    
    Rails.logger.info "Subscribing to channel #{channel.name} (#{channel.id})"
    
    mq = MQ.new
    mq.prefetch PrefetchCount
    @sessions[channel.id] = mq
    
    Queues.subscribe_ao channel, mq do |header, job|
      begin
        job.perform
        header.ack
      rescue PermanentException => ex
        channel.enabled = false
        channel.save!
      rescue TemporaryException => ex
        Queues.publish_notification ChannelUnsubscriptionJob.new(channel.id), @notifications_session
        EM.add_timer(@suspension_time) do 
          Queues.publish_notification ChannelSubscriptionJob.new(channel.id), @notifications_session            
        end
      end
    end
  end
  
  def unsubscribe_from_channel(channel_id)
    Rails.logger.info "Unsubscribing from channel #{channel_id}"
  
    mq = @sessions.delete(channel_id)
    mq.close if mq
  end
  
  def stop(stop_event_machine = true)
    Rails.logger.info "Stopping"
  
    super()
    
    @sessions.keys.each { |k| unsubscribe_from_channel k }
    @notifications_session.close
    EM.stop_event_loop if stop_event_machine
  end

end
