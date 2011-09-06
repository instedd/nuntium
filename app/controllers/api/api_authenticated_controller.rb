class ApiAuthenticatedController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      success = false
      account_name, app_name = username.split '/'
      app_name, account_name = username.split '@' if app_name.nil?
      if account_name && app_name
        @account = Account.find_by_id_or_name account_name
        if @account
          @application = @account.applications.find_by_name app_name
          if @application && @application.authenticate(password)
            @application.account = @account
            success = true
          end
        end
      else
        @account = Account.find_by_id_or_name username
        if @account && @account.authenticate(password)
          success = true
        end
      end
      success
    end
  end

end
