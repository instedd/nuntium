module Queues
  class << self
  
    def publish_ao(msg, job)
      ao_exchange.publish(job.to_yaml, 
        :routing_key => ao_routing_key_for(msg.channel), 
        :persistent => true)
    end
    
    def bind_ao(channel, mq = MQ)
      ao_queue_for(channel, mq).bind(ao_exchange(mq), 
        :routing_key => ao_routing_key_for(channel))
    end
    
    def subscribe_ao(channel, mq = MQ)
      bind_ao(channel, mq).subscribe(:ack => true) do |header, job| 
        yield header, deserialize(job)
      end
    end
    
    def unsubscribe_ao(channel, mq = MQ)
      bind_ao(channel, mq).unsubscribe
    end
    
    def publish_notification(job)
      notifications_exchange.publish(job.to_yaml)
    end
        
    def subscribe_notifications(mq = MQ)
      bind_notifications(mq).subscribe do |header, job|
        yield header, deserialize(job)
      end
    end
    
    def reconnect(mq)
      new_mq = MQ.new
      mq.close
      new_mq
    end
    
    def deserialize(source)
      handler = YAML.load(source) rescue nil

      unless handler.respond_to?(:perform)
        if handler.nil? && source =~ ParseObjectFromYaml
          handler_class = $1
        end
        attempt_to_load(handler_class || handler.class)
        handler = YAML.load(source)
      end

      return handler if handler.respond_to?(:perform)

      raise DeserializationError,
        'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
    rescue TypeError, LoadError, NameError => e
      raise DeserializationError,
        "Job failed to load: #{e.message}. Try to manually require the required file."
    end
    
    private
    
    def ao_exchange(mq = MQ)
      mq.topic('ao_messages', :durable => true)
    end
    
    def ao_queue_for(channel, mq = MQ)
      mq.queue(ao_queue_name_for(channel), :durable => true)
    end
    
    def ao_queue_name_for(channel)
      "ao_queue.#{channel.application_id}.#{channel.kind}.#{channel.id}"
    end
    
    def ao_routing_key_for(channel)
      "ao.#{channel.application_id}.#{channel.kind}.#{channel.id}"
    end
    
    def notifications_exchange(mq = MQ)
      mq.fanout('notifications_messages')
    end
    
    def notifications_queue(mq = MQ)
      mq.queue('notifications_queue')
    end
    
    def bind_notifications(mq = MQ)
      notifications_queue(mq).bind(notifications_exchange(mq))
    end

    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    def attempt_to_load(klass)
       klass.constantize
    end

  end
end
