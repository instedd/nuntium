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

class QstServerChannelTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make! :configuration => {:password => 'foo', :password_confirmation => 'foo'}
  end

  test "should not create if password is blank" do
    chan = QstServerChannel.make
    chan.password = chan.password_confirmation = ''
    assert_false chan.save
  end

  test "should not save if password confirmation is wrong" do
    @chan.password_confirmation = 'foo2'
    assert_false @chan.save
  end

  test "should authenticate" do
    assert @chan.authenticate('foo')
    assert_false @chan.authenticate('foo2')
  end

  test "should keep old password if save with blank password" do
    @chan.password = @chan.password_confirmation = ''
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo')
  end

  test "should rehash password after password changed" do
    @chan.password = @chan.password_confirmation = 'foo2'
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo2')
  end

  test "should update" do
    assert @chan.save
  end

  test "should validate presence of ticket if use_ticket is set to true" do
    assert @chan.valid?
    @chan.ticket_code = ''
    @chan.use_ticket = true
    assert_false @chan.valid?
  end

  test "should add carrier if matches number" do
    carrier = Carrier.make
    address = "#{carrier.country.phone_prefix}#{carrier.prefixes}987654321"
    chan = QstServerChannel.make :address => address, :configuration => {:password => 'foo', :password_confirmation => 'foo'}
    assert_equal carrier.guid, chan.carrier_guid
  end

  test "should add carrier if matches number (multiple)" do
    carrier = Carrier.make
    country = Country.make :phone_prefix => "98"
    carrier1 = country.carriers.make :prefixes => "12"
    carrier2 = country.carriers.make :prefixes => "1"
    chan = QstServerChannel.make :address => "9812", :configuration => {:password => 'foo', :password_confirmation => 'foo'}
    assert_equal [carrier1.guid, carrier2.guid].sort, chan.carrier_guid.split(",").sort
  end

  test "should not add carrier if doesn't match number" do
    carrier = Carrier.make
    chan = QstServerChannel.make :address => "1234", :configuration => {:password => 'foo', :password_confirmation => 'foo'}
    assert_equal nil, chan.carrier_guid
  end
end
