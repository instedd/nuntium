module Telemetry::Lifespan
  def self.touch_application(application)
    InsteddTelemetry.timespan_update('application_lifespan', {application_id: application.id}, application.created_at, Time.now.utc) if application.present?
  end

  def self.touch_account(account)
    InsteddTelemetry.timespan_update('account_lifespan', {account_id: account.id}, account.created_at, Time.now.utc) if account.present?
  end
end
