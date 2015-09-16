module ActiveRecordTelemetry

  extend ActiveSupport::Concern

  def touch_application_lifespan(application)
    InsteddTelemetry.timespan_update('application_lifespan', {application_id: application.id}, application.created_at, Time.now.utc) if application.present?
  end

  def touch_account_lifespan(account)
    InsteddTelemetry.timespan_update('account_lifespan', {account_id: account.id}, account.created_at, Time.now.utc) if account.present?
  end
end

ActiveRecord::Base.send(:include, ActiveRecordTelemetry)
