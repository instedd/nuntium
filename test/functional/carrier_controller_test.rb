require 'test_helper'

class CarrierControllerTest < ActionController::TestCase

  def setup
    Rails.cache.clear
  
    country = Country.create!(:name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54')
    carrier = Carrier.create!(:country => country, :name => 'Personal', :guid => "Some'Guid", :prefixes => '1, 2, 3')
    
    country2 = Country.create!(:name => 'Brazil', :iso2 => 'br', :iso3 =>'brz', :phone_prefix => '??')
    carrier2 = Carrier.create!(:country => country2, :name => 'Personal2', :guid => "Some'Guid2", :prefixes => '1, 2, 3')
  end

  ['ar', 'arg'].each do |country_code|
    test "index xml for country code #{country_code}" do
      get :index, :format => 'xml', :country_id => country_code
      assert_response :ok
      
      assert_select 'carriers' do
        assert_select "carrier[name=?]", 'Personal'
        assert_select "carrier[guid=?]", "Some'Guid"
        assert_select "carrier[country_iso2=?]", 'ar'
      end
    end
    
    test "index json for country code #{country_code}" do
      get :index, :format => 'json', :country_id => country_code
      assert_response :ok
      
      carriers = JSON.parse @response.body
      assert_equal 1, carriers.length
      assert_equal 'Personal', carriers[0]['name']
      assert_equal "Some'Guid", carriers[0]['guid']
      assert_equal 'ar', carriers[0]['country_iso2']
      
      ['id', 'country', 'country_id', 'clickatell_name', 'prefixes', 'created_at', 'updated_at'].each do |excluded|
        assert_false carriers[0].has_key? excluded
      end
    end
  end
  
  ['xml', 'json'].each do |format|
    test "index #{format} no matching country" do
      get :index, :format => format, :country_id => 'foo'
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
