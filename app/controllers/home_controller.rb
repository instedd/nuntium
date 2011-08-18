require 'will_paginate'

class HomeController < AccountAuthenticatedController
  def interactions
  end

  def logs
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @logs = @account.logs.order 'id DESC'
    @logs = @logs.search @search if @search.present?
    @logs = @logs.paginate :page => @page, :per_page => ResultsPerPage
    @logs = @logs.all
  end

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
