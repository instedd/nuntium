class HomeController < AccountAuthenticatedController
  def update_application_routing_rules
    @account.app_routing_rules = get_rules :apprules

    if !@account.save
      render :applications
    else
      flash[:notice] = 'Application Routing Rules were changed'
      redirect_to :applications
    end
  end
end
