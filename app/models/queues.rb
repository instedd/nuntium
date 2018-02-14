# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

module Queues
  class Header
    attr_reader :delivery_info
    attr_reader :properties

    def initialize(mq, delivery_info, properties = {})
      @mq = mq
      @delivery_info = delivery_info
      @properties = properties
    end

    def ack
      @mq.ack(delivery_info.delivery_tag, false)
    end
  end

  class << self
    def init
      $amqp_conn = Bunny.new $amqp_config, host: ENV["RABBITMQ_HOST"]

      $amqp_conn.start
      @default_mq = nil
    end

    def default_mq
      @default_mq ||= $amqp_conn.create_channel
    end

    def new_mq
      $amqp_conn.create_channel
    end

    def recycle_mq(mq)
      new_mq = $amqp_conn.create_channel
      mq.close
      new_mq
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

      bind_ao(channel, mq).subscribe(:manual_ack => true) do |delivery_info, properties, payload|
        job = payload.deserialize_job
        header = Header.new(mq, delivery_info, properties)
        yield header, job
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

      bind_notifications(id, routing_key, mq).subscribe do |delivery_info, properties, payload|
        task = payload.deserialize_job
        header = Header.new(mq, delivery_info, properties)
        yield header, task
      end
    end

    def subscribe(queue_name, ack, durable, mq = nil)
      mq ||= default_mq

      mq.queue(queue_name, :durable => durable).subscribe(:manual_ack => ack) do |delivery_info, properties, payload|
        job = payload.deserialize_job
        header = Header.new(mq, delivery_info, properties)
        yield header, job
      end
    end

    def delete(queue_name, durable, mq = nil)
      mq ||= default_mq

      mq.queue(queue_name, :durable => durable).delete
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
