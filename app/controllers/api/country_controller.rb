class CountryController < ApplicationController

  def index
    case params[:format]
    when 'xml'
      render :xml => countries.to_xml
    when 'json'
      render :json => countries.to_json(:except => [:id, :created_at, :updated_at])
    else
      head :bad_request
    end
  end
  
  private
  
  def countries
    Country.all
  end

end
