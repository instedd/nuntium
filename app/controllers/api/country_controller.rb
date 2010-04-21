class CountryController < ApplicationController

  def index
    render params[:format].to_sym => Country.all
  end

end
