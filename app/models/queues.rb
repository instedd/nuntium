module Queues
  class << self
    def default_mq
      @default_mq ||= MQ.new
    end

    def publish_application(application, job)
      application_exchange.publish(job.to_yaml,
        :routing_key => application_routing_key_for(application),
        :persistent => true)
    end

    def bind_application(application, mq = nil)
      mq ||= default_mq

      application_queue_for(application, mq).bind(application_exchange(mq),
        :routing_key => application_routing_key_for(application))
    end

    def publish_ao(msg, job)
      ao_exchange.publish(job.to_yaml,
        :routing_key => ao_routing_key_for(msg.channel),
        :persistent => true)
    end

    def bind_ao(channel, mq = nil)
      mq ||= default_mq

      ao_queue_for(channel, mq).bind(ao_exchange(mq),
        :routing_key => ao_routing_key_for(channel))
    end

    def subscribe_ao(channel, mq = nil)
      mq ||= default_mq

      bind_ao(channel, mq).subscribe(:ack => true) do |header, job|
        yield header, job.deserialize_job
      end
    end

    def unsubscribe_ao(channel, mq = nil)
      mq ||= default_mq

      bind_ao(channel, mq).unsubscribe
    end

    def publish_notification(job, routing_key, mq = nil)
      mq ||= default_mq

      notifications_exchange(mq).publish(job.to_yaml, :routing_key => routing_key)
    end

    def purge_ao(channel, mq = nil)
      mq ||= default_mq

      bind_ao(channel, mq).purge
    end

    def purge_notifications(id, routing_key, mq = nil)
      mq ||= default_mq

      bind_notifications(id, routing_key, mq).purge
    end

    def publish_cron_task(task, mq = nil)
      mq ||= default_mq

      cron_tasks_exchange(mq).publish(task.to_yaml, :persistent => true)
    end

    def subscribe_notifications(id, routing_key, mq = nil)
      mq ||= default_mq

      bind_notifications(id, routing_key, mq).subscribe do |header, task|
        yield header, task.deserialize_job
      end
    end

    def subscribe(queue_name, ack, durable, mq = nil)
      mq ||= default_mq

      mq.queue(queue_name, :durable => durable).subscribe(:ack => ack) do |header, job|
        yield header, job.deserialize_job
      end
    end

    def delete(queue_name, durable, mq = nil)
      mq ||= default_mq

      mq.queue(queue_name, :durable => durable).delete
    end

    def reconnect(mq)
      new_mq = MQ.new
      mq.close
      new_mq
    end

    def application_exchange(mq = nil)
      mq ||= default_mq

      mq.topic('applications', :durable => true)
    end

    def application_queue_for(application, mq = nil)
      mq ||= default_mq

      mq.queue(application_queue_name_for(application), :durable => true)
    end

    def application_queue_name_for(application)
      "application_queue.#{application.id}"
    end

    def application_routing_key_for(application)
      "application.#{application.id}"
    end

    def ao_exchange(mq = nil)
      mq ||= default_mq

      mq.topic('ao_messages', :durable => true)
    end

    def ao_queue_for(channel, mq = nil)
      mq ||= default_mq

      mq.queue(ao_queue_name_for(channel), :durable => true)
    end

    def ao_queue_name_for(channel)
      "ao_queue.#{channel.account_id}.#{channel.kind}.#{channel.id}"
    end

    def ao_routing_key_for(channel)
      "ao.#{channel.account_id}.#{channel.kind}.#{channel.id}"
    end

    def notifications_exchange(mq = nil)
      mq ||= default_mq

      mq.topic('notifications')
    end

    def notifications_queue(id, routing_key, mq = nil)
      mq ||= default_mq

      mq.queue("notifications_queue_#{routing_key}_#{id}", :auto_delete => true)
    end

    def bind_notifications(id, routing_key, mq = nil)
      mq ||= default_mq

      notifications_queue(id, routing_key, mq).bind(
        notifications_exchange(mq),
        :routing_key => routing_key)
    end

    def cron_tasks_queue(mq = nil)
      mq ||= default_mq

      mq.queue("cron_tasks_queue")
    end

    def cron_tasks_exchange(mq = nil)
      mq ||= default_mq

      mq.direct("cron_tasks")
    end

    def bind_cron_tasks(mq = nil)
      mq ||= default_mq

      cron_tasks_queue(mq).bind(cron_tasks_exchange(mq))
    end
  end
end
