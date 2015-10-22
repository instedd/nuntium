module ActiveRecordTelemetry

  extend ActiveSupport::Concern

  def touch_application_lifespan
    Telemetry::Lifespan.touch_application self.application
  end

  def touch_account_lifespan
    Telemetry::Lifespan.touch_account self.account
  end
end

ActiveRecord::Base.send(:include, ActiveRecordTelemetry)
