class LogsController < ApplicationController
  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @logs = account.logs.includes(:application, :channel).order 'id DESC'
    @logs = @logs.search @search if @search.present?
    @logs = @logs.paginate :page => @page, :per_page => ResultsPerPage
    @logs = @logs.all
  end
end
