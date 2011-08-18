class SettingsController < ApplicationController
  def update
    if account.update_attributes params[:account]
      redirect_to settings_path, :notice => 'Settings updated'
    else
      render :show
    end
  end
end
