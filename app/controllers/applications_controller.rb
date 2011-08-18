class ApplicationsController < ApplicationController
  include RulesControllerCommon

  before_filter :set_application_parameters, :only => [:create, :update]
  def set_application_parameters
    application.ao_rules = get_rules :aorules
    application.at_rules = get_rules :atrules
  end

  def create
    if application.save
      redirect_to applications_path, :notice => "Application #{application.name} creaetd"
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
end
