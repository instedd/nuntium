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

class TicketTest < ActiveSupport::TestCase

  test "Code is unique" do
    Ticket.make! :pending, :code => '1234'
    assert_raise ActiveRecord::RecordInvalid do
      Ticket.make! :pending, :code => '1234'
    end
  end

  test "Skip code if duplicate" do
    Ticket.stubs(:rand).returns(1234)

    Ticket.checkout
    Ticket.checkout
  end

  test "code can start with zero" do
    Ticket.stubs(:rand).returns(123)

    assert_equal "0123", Ticket.checkout.code
    assert_equal "0124", Ticket.checkout.code
  end

  test "Code generation restarts from zero" do
    Ticket.stubs(:rand).returns(9999)

    assert_equal "9999", Ticket.checkout.code
    assert_equal "0000", Ticket.checkout.code
  end

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

  test "Checkout ticket use params as initial data" do
    data = { :address => '12345678', :country_code => '54' }
    ticket = Ticket.checkout data
    stored = Ticket.find_by_code ticket.code

    assert_equal data, stored.data
  end

  test "Checked out tickets can be completed" do
    ticket = Ticket.checkout
    assert_equal 'pending', ticket.status

    pending = Ticket.keep_alive ticket.code, ticket.secret_key
    assert_equal 'pending', pending.status

    Ticket.complete ticket.code
    completed = Ticket.keep_alive ticket.code, ticket.secret_key

    assert_equal 'complete', completed.status
  end

  test "Upon keep alive a complete ticket updated data is provided" do
    ticket = Ticket.checkout :a => 1
    Ticket.complete ticket.code, :b => 2

    completed = Ticket.keep_alive ticket.code, ticket.secret_key

    assert_equal ({ :a => 1, :b => 2 }), completed.data
  end

  test "Cannot complete already completed tickets" do
    ticket = Ticket.checkout
    Ticket.complete ticket.code

    assert_raise RuntimeError, "Invalid code" do
      Ticket.complete ticket.code
    end
  end

  test "Cannot complete with invalid ticket code" do
    assert_raise RuntimeError, "Invalid code" do
      Ticket.complete 'not-a-code'
    end
  end

  # ensure unique code
end
