class ApiAuthenticatedController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account, @application = Account.authenticate username, password
      @account
    end
  end

end
