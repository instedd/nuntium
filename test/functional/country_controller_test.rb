require 'test_helper'

class CountryControllerTest < ActionController::TestCase

  test "index" do
    c = Country.create!({:name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54'})
    
    get :index, :format => 'xml'
    assert_response :ok
    
    assert_select 'countries' do
      assert_select "country[name=?]", c.name
      assert_select "country[iso2=?]", c.iso2
      assert_select "country[iso3=?]", c.iso3
      assert_select "country[phonePrefix=?]", c.phone_prefix
    end
  end

end
