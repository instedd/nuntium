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

  before_filter :set_application_parameters, :only => [:create, :update]
  before_filter :deny_access_if_logged_in_as_application, :only => [:create, :destroy, :routing_rules]

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
end
