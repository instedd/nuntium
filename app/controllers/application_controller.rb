# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  ResultsPerPage = 10

  expose(:account) { Account.find_by_id session[:account_id] }

  expose(:applications) { account.applications }
  expose(:application)

  expose(:channels) { account.channels }
  expose(:channel)

  expose(:app_routing_rules) { account.app_routing_rules }

  before_filter :check_login
  def check_login
    unless session[:account_id]
      redirect_to new_session_path
      return
    end

    unless account
      session.delete :account_id
      redirect_to new_session_path
      return
    end
  end
end
