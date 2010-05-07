class ApiCountryController < ApplicationController

  def index
    respond_to do |format|
      format.xml { render :xml => countries.to_xml(:root => 'countries', :skip_types => true) }
      format.json { render :json => countries.to_json(:only => [:name, :iso2, :iso3, :phone_prefix]) }
    end
  end
  
  private
  
  def countries
    Country.all
  end

end
