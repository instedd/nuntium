class ApiCarrierController < ApplicationController

  # GET /api/carriers.:format?country_id=:country_id
  def index
    if params[:country_id]
      country = Country.find_by_iso2_or_iso3 params[:country_id]
      return head :not_found unless country
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

    return head :not_found unless carrier

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
