# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  ResultsPerPage = 10

  expose(:account) do
    if session[:account_id]
      Account.find_by_id session[:account_id]
    else
      logged_in_application.try(:account)
    end
  end

  expose(:applications) do
    apps = account.applications
    apps = apps.where(:id => logged_in_application.id) if logged_in_application
    apps
  end
  expose(:application)

  expose(:logged_in_application) { session[:application_id] && Application.find_by_id(session[:application_id]) }

  expose(:channels) do
    channels = account.channels.includes(:application)
    channels = channels.where("application_id IS NULL OR application_id = ?", logged_in_application.id) if logged_in_application
    channels
  end
  expose(:channel) do
    channel = if params[:id] || params[:channel_id]
                channel = channels.find(params[:id] || params[:channel_id])
                channel.attributes = params[:channel] if params[:channel]
                channel
              elsif params[:channel]
                params[:channel][:kind].to_channel.new params[:channel]
              elsif params[:kind]
                params[:kind].to_channel.new
              else
                Channel.new
              end
    channel.application = logged_in_application if !channel.persisted? && logged_in_application
    channel
  end

  expose(:app_routing_rules) { account.app_routing_rules }

  before_filter :check_login
  def check_login
    unless session[:account_id] || session[:application_id]
      redirect_to new_session_path
      return
    end

    unless account
      session.delete :account_id
      session.delete :application_id
      redirect_to new_session_path
      return
    end
  end

  def deny_access_if_logged_in_as_application
    redirect_to root_path if logged_in_application
  end
end
