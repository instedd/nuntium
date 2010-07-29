require 'test_helper'

class AddressControllerTest < ActionController::TestCase

  def setup
    @chan = Channel.make :qst_server, :configuration => {:password => 'pass'}
  end
  
  test "updates address" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'pass')
  
    get :update, :address => 'foo', :account_id => @chan.account.name
    
    @chan.reload
    assert_equal 'foo', @chan.address
  end
  
 end
