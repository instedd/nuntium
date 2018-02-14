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

class ApiCountryController < ApplicationController
  skip_before_action :check_login

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
