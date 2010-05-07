class ApiCountryController < ApplicationController

  def index
    case params[:format]
    when 'xml'
      render :xml => countries.to_xml
    when 'json'
      render :json => countries.to_json(:only => [:name, :iso2, :iso3, :phone_prefix])
    else
      head :bad_request
    end
  end
  
  private
  
  def countries
    Country.all
  end

end
