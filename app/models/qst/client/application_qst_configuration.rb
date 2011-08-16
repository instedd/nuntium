module ApplicationQstConfiguration
  def application
    @application ||= Application.find_by_id @application_id
  end

  def account
    @account ||= application.account
  end

  def get_url_user_and_password
    [application.interface_url, application.interface_user, application.interface_password]
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
