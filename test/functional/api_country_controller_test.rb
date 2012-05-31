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

class ApiCountryControllerTest < ActionController::TestCase

  def setup
    @attributes = {:name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54'}
    Country.create!(@attributes)
  end

  test "index xml" do
    get :index, :format => 'xml'
    assert_response :ok

    assert_select 'countries' do
      @attributes.each do |key, value|
        assert_select "country[#{key}=?]", value
      end
    end
  end

  test "index json" do
    get :index, :format => 'json'
    assert_response :ok

    countries = JSON.parse @response.body
    assert_equal 1, countries.length
    @attributes.each do |key, value|
      assert_equal value, countries[0][key.to_s]
    end
    ['id', 'created_at', 'updated_at'].each do |excluded|
      assert_false countries[0].has_key? excluded
    end
  end

end
