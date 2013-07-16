# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  ResultsPerPage = 10

  expose(:account) { current_user.try(:current_account) }
  expose(:user_account) { current_user.user_accounts.where(account_id: account.id).first }
  expose(:account_admin?) { user_account.try(:role) == 'admin' }

  expose(:user_applications) { current_user.user_applications.where(account_id: account.id).all }

  expose(:applications) do
    apps = account.applications
    unless account_admin?
      apps = apps.where(id: user_applications.map(&:application_id))
    end
    apps
  end
  expose(:application)

  expose(:user_channels) { current_user.user_channels.where(account_id: account.id).all }

  expose(:channels) do
    chans = account.channels.includes(:application)
    unless account_admin?
      chans = chans.where("id IN (?) or application_id IN (?)", user_channels.map(&:channel_id), user_applications.map(&:application_id))
    end
    chans
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
    channel
  end

  expose(:app_routing_rules) { account.app_routing_rules }

  def application_admin?(application)
    return true if account_admin?
    user_applications.find { |ua| ua.application_id == application.id }.try(:role) == 'admin'
  end
  helper_method :application_admin?

  def channel_admin?(channel)
    return true if account_admin?
    (user_channels.find { |uc| uc.channel_id == channel.id }.try(:role) == 'admin') ||
      (user_applications.find { |ua| ua.application_id == channel.application_id }.try(:role) == 'admin')
  end
  helper_method :channel_admin?

  before_filter :check_login
  def check_login
    authenticate_user!
  end

  before_filter :check_account
  def check_account
    redirect_to new_account_path if user_signed_in? && !account
  end

  def check_account_admin
    redirect_to root_path unless account_admin?
  end
end
