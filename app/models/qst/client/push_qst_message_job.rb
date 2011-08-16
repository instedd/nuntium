class PushQstMessageJob < AbstractPushQstMessageJob
  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end

  def application
    @application ||= Application.find_by_id @application_id
  end

  def account
    @account ||= application.account
  end

  def message_class
    ATMessage
  end

  def max_tries
    account.max_tries
  end

  def messages
    account.at_messages
  end

  def get_url_user_and_password
    [application.interface_url, application.interface_user, application.interface_password]
  end

  def save_last_id(last_id)
    application.last_at_guid = last_id
    application.save!
  end

  def on_401(message)
    application.logger.error :application_id => application.id, :message => message
    application.interface = 'rss'
    application.save!
  end

  def on_exception(message)
    application.logger.error :application_id => application.id, :message => message
  end
end
