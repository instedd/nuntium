class ApiCarrierController < ApplicationController

  def index
    country_id = params[:country_id]
    
    country = nil
    if country_id.nil?
      # Nothing
    elsif country_id.length == 2
      country = Country.find_by_iso2 country_id
      return head :bad_request unless country
    elsif country_id.length == 3
      country = Country.find_by_iso3 country_id
      return head :bad_request unless country
    else
      return head :bad_request
    end
    
    respond_to do |format|
      format.xml { render :xml => (carriers_for country).to_xml(:root => 'carriers') }
      format.json { render :json => (carriers_for country).to_json }
    end
  end
  
  private
  
  def carriers_for(country)
    if country.nil?
      Carrier.all_with_countries
    else
      carriers = Carrier.find_by_country_id country.id
      carriers.each {|x| x.country = country}
      carriers
    end
  end

end
