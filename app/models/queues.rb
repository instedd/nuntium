module Queues
  class << self
  
    def publish_ao(msg, job)
      ao_exchange.publish(job.to_yaml, 
        :routing_key => ao_routing_key_for(msg.channel), 
        :persistent => true)
    end
    
    def bind_ao(channel)
      ao_queue_for(channel).bind(ao_exchange, 
        :routing_key => ao_routing_key_for(channel))
    end
    
    def subscribe_ao(channel)
      bind_ao(channel).subscribe(:ack => true) do |header, job| 
        yield header, deserialize(job)
      end
    end
    
    def unsubscribe_ao(channel)
      bind_ao(channel).unsubscribe
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
    
    def ao_exchange
      MQ.topic('ao_messages', :durable => true)
    end
    
    def ao_queue_for(channel)
      MQ.queue(ao_queue_name_for(channel), :durable => true)
    end
    
    def ao_queue_name_for(channel)
      "ao_queue.#{channel.application_id}.#{channel.kind}.#{channel.id}"
    end
    
    def ao_routing_key_for(channel)
      "ao.#{channel.application_id}.#{channel.kind}.#{channel.id}"
    end

    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    def attempt_to_load(klass)
       klass.constantize
    end

  end
end
