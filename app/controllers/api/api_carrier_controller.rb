# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class ApiCarrierController < ApplicationController
  skip_before_action :check_login

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
