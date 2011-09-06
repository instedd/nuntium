class SettingsController < ApplicationController
  before_filter :deny_access_if_logged_in_as_application

  def update
    if account.update_attributes params[:account]
      redirect_to settings_path, :notice => 'Settings updated'
    else
      render :show
    end
  end
end
