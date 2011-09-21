# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
module ServiceChannel
  extend ActiveSupport::Concern

  included do
    after_create :bind_queue
    after_create :publish_start_channel
    after_enabled :publish_start_channel
    after_disabled :publish_stop_channel
    after_changed :publish_restart_channel
    before_destroy :publish_stop_channel
  end

  module InstanceMethods
    def handle(msg)
      Queues.publish_ao msg, create_job(msg)
    end

    def on_changed
      publish_restart_channel
    end

    def publish_start_channel
      Queues.publish_notification StartChannelJob.new(id), self.class.kind
      true
    end

    def publish_stop_channel
      Queues.publish_notification StopChannelJob.new(id), self.class.kind
      true
    end

    def publish_restart_channel
      Queues.publish_notification RestartChannelJob.new(id), self.class.kind
      true
    end

    def service
      "#{self.class.identifier}Service".constantize.new self
    end

    def has_connection?
      true
    end

    def bind_queue
      Queues.bind_ao self
    end
  end
end
