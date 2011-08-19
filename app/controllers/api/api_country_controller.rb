class ApiCountryController < ApplicationController
  skip_filter :check_login

  # GET /api/countries.:format
  def index
    respond_to do |format|
      format.xml { render :xml => countries.to_xml(:root => 'countries', :skip_types => true) }
      format.json { render :json => countries.to_json(:only => [:name, :iso2, :iso3, :phone_prefix]) }
    end
  end

  # GET /api/countries/:iso.:format
  def show
    iso = params[:iso]
    country = Country.find_by_iso2_or_iso3 iso
    return head :not_found unless country

    respond_to do |format|
      format.xml { render :xml => country.to_xml(:skip_types => true) }
      format.json { render :json => country.to_json(:only => [:name, :iso2, :iso3, :phone_prefix]) }
    end
  end

  private

  def countries
    Country.all
  end

end
