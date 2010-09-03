module Queues

  class << self
  
    def publish_application(application, job)
      application_exchange.publish(job.to_yaml, 
        :routing_key => application_routing_key_for(application), 
        :persistent => true)
    end
    
    def bind_application(application, mq = MQ)
      application_queue_for(application, mq).bind(application_exchange(mq), 
        :routing_key => application_routing_key_for(application))
    end
  
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
    
    def publish_notification(job, routing_key, mq = MQ)
      notifications_exchange(mq).publish(job.to_yaml, :routing_key => routing_key)
    end

		def purge_ao(channel, mq = MQ)
			bind_ao(channel, mq).purge
		end

		def purge_notifications(id, routing_key, mq = MQ)
			bind_notifications(id, routing_key, mq).purge
		end
		
		def publish_cron_task(task, mq = MQ)
		  cron_tasks_exchange(mq).publish(task.to_yaml, :persistent => true)
    end
    
    def subscribe_notifications(id, routing_key, mq = MQ)
      bind_notifications(id, routing_key, mq).subscribe do |header, task|
        yield header, deserialize(task)
      end
    end
    
    def subscribe(queue_name, ack, durable, mq = MQ)
      mq.queue(queue_name, :durable => durable).subscribe(:ack => ack) do |header, job|
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
    
    def application_exchange(mq = MQ)
      mq.topic('applications', :durable => true)
    end
    
    def application_queue_for(application, mq = MQ)
      mq.queue(application_queue_name_for(application), :durable => true)
    end
    
    def application_queue_name_for(application)
      "application_queue.#{application.id}"
    end
    
    def application_routing_key_for(application)
      "application.#{application.id}"
    end
    
    def ao_exchange(mq = MQ)
      mq.topic('ao_messages', :durable => true)
    end
    
    def ao_queue_for(channel, mq = MQ)
      mq.queue(ao_queue_name_for(channel), :durable => true)
    end
    
    def ao_queue_name_for(channel)
      "ao_queue.#{channel.account_id}.#{channel.kind}.#{channel.id}"
    end
    
    def ao_routing_key_for(channel)
      "ao.#{channel.account_id}.#{channel.kind}.#{channel.id}"
    end
    
    def notifications_exchange(mq = MQ)
      mq.topic('notifications')
    end
    
    def notifications_queue(id, routing_key, mq = MQ)
      mq.queue("notifications_queue_#{routing_key}_#{id}", :auto_delete => true)
    end
    
    def bind_notifications(id, routing_key, mq = MQ)
      notifications_queue(id, routing_key, mq).bind(
        notifications_exchange(mq), 
        :routing_key => routing_key)
    end
    
    def cron_tasks_queue(mq = MQ)
      mq.queue("cron_tasks_queue")
    end
    
    def cron_tasks_exchange(mq = MQ)
      mq.direct("cron_tasks")
    end
    
    def bind_cron_tasks(mq = MQ)
      cron_tasks_queue(mq).bind(cron_tasks_exchange(mq))
    end

    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    def attempt_to_load(klass)
       klass.constantize
    end
    
    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

  end
  
end
