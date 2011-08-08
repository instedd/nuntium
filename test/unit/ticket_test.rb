require 'test_helper'

class TicketTest < ActiveSupport::TestCase

  test "Checkout ticket gets code and use params as data" do
    ticket = Ticket.checkout
    assert !ticket.code.blank?
    
    stored = Ticket.find_by_code ticket.code
    assert_equal ticket.id, stored.id
  end
  
  test "Checked out tickets do not reuse codes" do
    ticket1 = Ticket.checkout
    ticket2 = Ticket.checkout
    
    assert_not_equal ticket1.code, ticket2.code
  end
  
  test "Checked out tickets have secret_key" do
    assert !Ticket.checkout.secret_key.blank?
  end
  
  test "Checked out tickets expire in one day" do
    set_current_time base_time
    ticket = Ticket.checkout
    assert_equal base_time + 1.day, ticket.expiration
  end
  
  test "Can keep alive ticket with right secret_key" do
    ticket = Ticket.checkout
    alive = Ticket.keep_alive ticket.code, ticket.secret_key
    
    assert_equal alive.id, ticket.id
  end

  test "Cannot keep alive ticket with wrong code" do
    assert_raise RuntimeError do
      Ticket.keep_alive 'not-a-code', 'not-the-secret-key'
    end
  end
  
  test "Cannot keep alive ticket with wrong secret_key" do
    ticket = Ticket.checkout
    assert_raise RuntimeError, "Invalid code or secret key" do
      Ticket.keep_alive ticket.code, 'not-the-secret-key'
    end
  end
  
  test "keep alive extend expiration" do
    set_current_time base_time
    ticket = Ticket.checkout
    set_current_time base_time + 3.hours
    alive = Ticket.keep_alive ticket.code, ticket.secret_key
    
    assert_equal base_time + 3.hours + 1.day, alive.expiration
  end
  
  test "remove expired tickets" do
    set_current_time base_time
    Ticket.checkout

    set_current_time base_time + 20.hours
    ticket = Ticket.checkout
      
    set_current_time base_time + 36.hours
    Ticket.remove_expired
    
    assert_equal 1, Ticket.all.count
    assert_equal ticket.id, Ticket.all.first.id
  end
  
  #test "Checkout ticket use params as initial data"
#   :address => '12345678', :country_code => '54'  
  #test "Checked out tickets can be completed"
  #test "Upon keep alive a complete ticket updated data is provided"
    
end
