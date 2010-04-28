class ApplicationAuthenticatedController < ApplicationController

  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name params[:account_name]
      if @account
        @application = Application.first :conditions => ['account_id = ? AND name = ?', @account.id, username]
        if @application and @application.authenticate password
          @application.account = @account
          true
        else
          false
        end
      else
        false
      end
    end
  end

end
