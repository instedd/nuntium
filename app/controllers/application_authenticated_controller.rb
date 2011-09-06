module ApplicationAuthenticatedController
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account, @application = Account.authenticate username, password, :only_application => true
      @account && @application && @account.name == params[:account_name] && @application.name == params[:application_name]
    end
  end
end
