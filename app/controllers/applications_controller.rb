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

class ApplicationsController < ApplicationController
  include RulesControllerCommon

  before_action :set_application_parameters, :only => [:create, :update]
  before_action :check_account_admin, :only => [:create, :routing_rules]
  before_action :check_application_admin, :only => [:edit, :update, :destroy]

  def set_application_parameters
    application.account_id = account.id
    application.ao_rules = get_rules :aorules
    application.at_rules = get_rules :atrules
  end

  def create
    if application.save
      redirect_to applications_path, :notice => "Application #{application.name} created"
    else
      render :new
    end
  end

  def update
    if application.save
      redirect_to applications_path, :notice => "Application #{application.name} updated"
    else
      render :edit
    end
  end

  def destroy
    application.destroy
    redirect_to applications_path, :notice => "Application #{application.name} deleted"
  end

  def routing_rules
    account.app_routing_rules = get_rules :apprules

    if account.save
      redirect_to applications_path, :notice => 'Application Routing Rules were changed'
    else
      render 'index'
    end
  end

  def logs
    @page = params[:page].presence || 1

    @logs = application.logs.includes(:channel).order('logs.id DESC')
    @logs = @logs.paginate_logs :page => @page
  end

  private

  def check_application_admin
    redirect_to applications_path unless application_admin?(application)
  end
end
