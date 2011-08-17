require 'test_helper'

class TicketsControllerTest < ActionController::TestCase
  test "checkout ticket and with data" do
    post :create, :format => 'json', :country_iso => 'ar', :address => '1234-5678'
    
    assert_response :ok
    
    ticket = JSON.parse @response.body
    
    assert !ticket['code'].blank?
    assert !ticket['secret_key'].blank?
    assert_equal 'ar', ticket['data']['country_iso']
    assert_equal '1234-5678', ticket['data']['address']
    
    assert !Ticket.find_by_code(ticket['code']).nil?
  end
  
  test "do not include route data in ticket data" do
    post :create, :format => 'json', :country_iso => 'ar', :address => '1234-5678'
    ticket = JSON.parse @response.body
    stored = Ticket.find_by_code(ticket['code'])
    
    assert_equal ({ :country_iso => 'ar', :address => '1234-5678' }), stored.data
  end
  
  test "allow keep alive of exiting tiket" do
    post :create, :format => 'json'
    ticket = JSON.parse @response.body  
    get :show, :format => 'json', :code => ticket['code'], :secret_key => ticket['secret_key']
    
    assert_response :ok
    renewal = JSON.parse @response.body
    
    assert_equal ticket, renewal
  end
  
  test "response not found with invalid code" do
    get :show, :format => 'json', :code => 'not-a-code', :secret_key => 'not-a-key'
    assert_response :not_found
  end
  
  test "clean expired tickets on checkout" do
    ticket1 = Ticket.make :pending, :expiration => (base_time - 25.hours)
    ticket2 = Ticket.make :status => 'complete', :expiration => (base_time - 26.hours)
    
    post :create, :format => 'json'
        
    assert_nil Ticket.find_by_id(ticket1.id)
    assert_nil Ticket.find_by_id(ticket2.id)
  end
end
