class ApiAuthenticatedController < ApplicationController

  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      success = false
      account_name, app_name = username.split('/')
      app_name, account_name = username.split('@') if app_name.nil?
      if account_name and app_name
        @account = Account.find_by_id_or_name account_name
        if @account
          @application = @account.find_application app_name
          if @application and @application.authenticate password
            @application.account = @account
            success = true
          end
        end
      else
        @account = Account.find_by_id_or_name username
        if @account and @account.authenticate password
          success = true
        end
      end
      success
    end
  end
  
end
