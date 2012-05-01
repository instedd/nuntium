# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
module ServiceChannel
  extend ActiveSupport::Concern

  included do
    after_create :create_managed_process
    after_enabled :enable_managed_process
    after_disabled :disable_managed_process
    after_changed :touch_managed_process
    before_destroy :destroy_managed_process
  end

  module InstanceMethods
    def handle(msg)
      Queues.publish_ao msg, create_job(msg)
    end

    def on_changed
      touch_managed_process
    end

    def create_managed_process
      bind_queue
      if enabled
        ManagedProcess.create!(
          :account_id => account.id,
          :name => managed_process_name,
          :start_command => "service_daemon_ctl.rb start #{Rails.env} #{id}",
          :stop_command => "service_daemon_ctl.rb stop #{Rails.env} #{id}",
          # The dot after service_daemon is important: do not change it (the service won't start)
          :pid_file => "service_daemon.#{id}..pid",
          :log_file => "service_daemon_#{id}..log",
          :enabled => enabled
        )
      end
    end

    def managed_process
      ManagedProcess.find_by_account_id_and_name account.id, managed_process_name
    end

    def enable_managed_process
      managed_process.try :enable!
      true
    end

    def disable_managed_process
      managed_process.try :disable!
      true
    end

    def touch_managed_process
      Rails.logger.info "TOUCH"
      Rails.logger.info caller
      managed_process.try :save!
    end

    def destroy_managed_process
      managed_process.try :destroy
    end

    def managed_process_name
      "#{kind}_daemon #{name}"
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
