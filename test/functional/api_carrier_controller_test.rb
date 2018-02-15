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

require 'test_helper'

class ApiCarrierControllerTest < ActionController::TestCase

  def setup
    @country = Country.make!
    @carrier = Carrier.make! :country => @country
    @country2 = Country.make!
    @carrier2 = Carrier.make! :country => @country2
  end

  def index_xml_for_country_code(code)
    get :index, :format => 'xml', :country_id => code
    assert_response :ok

    assert_select 'carriers' do
      assert_select "carrier[name=?]", @carrier.name
      assert_select "carrier[guid=?]", @carrier.guid
      assert_select "carrier[country_iso2=?]", @country.iso2
    end
  end

  def index_json_for_country_code(code)
    get :index, :format => 'json', :country_id => code
    assert_response :ok

    carriers = JSON.parse @response.body

    assert_equal 1, carriers.length
    assert_equal @carrier.name, carriers[0]['name']
    assert_equal @carrier.guid, carriers[0]['guid']
    assert_equal @country.iso2, carriers[0]['country_iso2']

    ['id', 'country', 'country_id', 'clickatell_name', 'prefixes', 'created_at', 'updated_at'].each do |excluded|
      assert_false carriers[0].has_key? excluded
    end
  end

  test "show xml" do
    get :show, :format => 'xml', :guid => @carrier.guid
    assert_response :ok

    assert_select "carrier[name=?]", @carrier.name
    assert_select "carrier[guid=?]", @carrier.guid
    assert_select "carrier[country_iso2=?]", @country.iso2
  end

  test "index xml for country code iso2" do
    index_xml_for_country_code @country.iso2
  end

  test "index json for country code iso2" do
    index_json_for_country_code @country.iso2
  end

  test "index xml for country code iso3" do
    index_xml_for_country_code @country.iso3
  end

  test "index json for country code iso3" do
    index_json_for_country_code @country.iso3
  end

  ['xml', 'json'].each do |format|
    test "index #{format} no matching country" do
      get :index, :format => format, :country_id => 'ZZZ'
      assert_response :not_found
    end
  end

  test "index xml no country" do
    get :index, :format => 'xml'
    assert_response :ok

    assert_select 'carriers' do
      assert_select "carrier", :count => 2
    end
  end

end
