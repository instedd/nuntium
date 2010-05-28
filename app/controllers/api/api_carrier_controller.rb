class ApiCarrierController < ApplicationController

  # GET /api/carriers.:format?country_id=:country_id
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
      format.xml { render :xml => (carriers_for country).to_xml(:root => 'carriers', :skip_types => true) }
      format.json { render :json => (carriers_for country).to_json }
    end
  end
  
  # GET /api/carriers/:guid.:format
  def show
    guid = params[:guid]
    carrier = Carrier.find_by_guid guid
    
    return head :bad_request unless carrier
    
    respond_to do |format|
      format.xml { render :xml => carrier.to_xml(:skip_types => true) }
      format.json { render :json => carrier.to_json }
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
