# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  ResultsPerPage = 10

  expose(:account) { Account.find_by_id session[:account_id] }

  expose(:applications) { account.applications }
  expose(:application)

  expose(:channels) { account.channels.includes(:application) }
  expose(:channel) do
    if params[:id] || params[:channel_id]
      channel = channels.find(params[:id] || params[:channel_id])
      channel.attributes = params[:channel] if params[:channel]
      channel
    elsif params[:channel]
      params[:channel][:kind].to_channel.new params[:channel]
    else
      params[:kind].to_channel.new
    end
  end

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
