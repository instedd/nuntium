require 'test_helper'

class ApiCarrierControllerTest < ActionController::TestCase

  Country.delete_all
  Carrier.delete_all
  @@country = Country.make
  @@carrier = Carrier.make :country => @@country    
  @@country2 = Country.make
  @@carrier2 = Carrier.make :country => @@country2

  [@@country.iso2, @@country.iso3].each do |country_code|
    test "index xml for country code #{country_code}" do
      get :index, :format => 'xml', :country_id => country_code
      assert_response :ok
      
      assert_select 'carriers' do
        assert_select "carrier[name=?]", @@carrier.name
        assert_select "carrier[guid=?]", @@carrier.guid
        assert_select "carrier[country_iso2=?]", @@country.iso2
      end
    end
    
    test "index json for country code #{country_code}" do
      get :index, :format => 'json', :country_id => country_code
      assert_response :ok
      
      carriers = JSON.parse @response.body
      
      assert_equal 1, carriers.length
      assert_equal @@carrier.name, carriers[0]['name']
      assert_equal @@carrier.guid, carriers[0]['guid']
      assert_equal @@country.iso2, carriers[0]['country_iso2']
      
      ['id', 'country', 'country_id', 'clickatell_name', 'prefixes', 'created_at', 'updated_at'].each do |excluded|
        assert_false carriers[0].has_key? excluded
      end
    end
  end
  
  ['xml', 'json'].each do |format|
    test "index #{format} no matching country" do
      get :index, :format => format, :country_id => 'ZZZ'
      assert_response :bad_request
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
