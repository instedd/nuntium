module ApplicationAuthenticatedController
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      success = false
      account_name, app_name = username.split('/')
      app_name, account_name = username.split('@') if app_name.nil?

      if account_name == params[:account_name] and app_name == params[:application_name]
        @account = Account.find_by_id_or_name account_name
        if @account
          @application = @account.applications.find_by_name app_name
          if @application and @application.authenticate password
            @application.account = @account
            success = true
          end
        end
      end
      success
    end
  end
end
