require 'test_helper'

class CountryControllerTest < ActionController::TestCase

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
    assert_false countries[0].has_key? 'id'
    assert_false countries[0].has_key? 'created_at'
    assert_false countries[0].has_key? 'updated_at'
  end

end
