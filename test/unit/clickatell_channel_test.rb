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

class ClickatellChannelTest < ActiveSupport::TestCase
  def setup
    @chan = ClickatellChannel.make!
  end

  include GenericChannelTest

  [:user, :from, :api_id, :cost_per_credit].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  [:password, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      @chan = ClickatellChannel.make
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "should validate cost per credit is decimal" do
    @chan.configuration[:cost_per_credit] = 'hello'
    assert_false @chan.save
  end

  test "should validate cost per credit is positive" do
    @chan.configuration[:cost_per_credit] = -1
    assert_false @chan.save
  end

  test "should use network for channel ao rounting filtering" do
    one = Country.make!
    two = Country.make!

    @chan.configuration[:network] = '44'
    @chan.save!
    ClickatellCoverageMO.create!(
      :country_id => one.id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )

    assert @chan.can_route_ao?(ao_with(one.iso2))
    assert_false @chan.can_route_ao?(ao_with(two.iso2))
  end

  test "should skip network if channel defines restrictions on country" do
    one = Country.make!
    two = Country.make!

    @chan.configuration[:network] = '44'
    @chan.restrictions['country'] = two.id # this overrides clickatell's coverage
    @chan.save!

    ClickatellCoverageMO.create!(
      :country_id => one.id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )

    assert_false @chan.can_route_ao?(ao_with(one.id))
    assert @chan.can_route_ao?(ao_with(two.id))
  end

  test "should use network for carrier ao rounting filtering" do
    country = Country.make!
    carrier1 = Carrier.make! :country => country
    carrier2 = Carrier.make! :country => country

    @chan.configuration[:network] = '44'
    @chan.save!

    ClickatellCoverageMO.create!(
      :country_id => country.id,
      :carrier_id => carrier1.id,
      :network => '44',
      :cost => 1
    )

    assert @chan.can_route_ao?(ao_with(country.iso2, carrier1.guid))
    assert_false @chan.can_route_ao?(ao_with(country.iso2, carrier2.guid))
  end

  test "should skip network if channel defines restrictions on carrier" do
    country = Country.make!
    carrier1 = Carrier.make! :country => country
    carrier2 = Carrier.make! :country => country

    @chan.configuration[:network] = '44'
    @chan.restrictions['carrier'] = carrier2.guid # this overrides clickatell's coverage
    @chan.save!

    ClickatellCoverageMO.create!(
      :country_id => country.id,
      :carrier_id =>  carrier1.id,
      :network => '44',
      :cost => 1
    )

    assert_false @chan.can_route_ao?(ao_with(country.iso2, carrier1.guid))
    assert @chan.can_route_ao?(ao_with(country.iso2, carrier2.guid))
  end

  test "clickatell channel augmented restrictions made based on coverage table" do
    country1 = Country.make!
    carrier1 = Carrier.make! :country => country1
    carrier2 = Carrier.make! :country => country1
    country2 = Country.make!
    carrier3 = Carrier.make! :country => country2
    carrier4 = Carrier.make! :country => country2

    @chan.configuration[:network] = '44'
    @chan.save!

    ClickatellCoverageMO.create!(:country_id => country1.id, :carrier_id => carrier1.id, :network => '44', :cost => 1)
    ClickatellCoverageMO.create!(:country_id => country1.id, :carrier_id => carrier2.id, :network => '44', :cost => 1)
    ClickatellCoverageMO.create!(:country_id => country2.id, :carrier_id => carrier3.id, :network => '44', :cost => 1)
    ClickatellCoverageMO.create!(:country_id => country2.id, :carrier_id => carrier4.id, :network => '44', :cost => 1)

    assert_equal ({
      'carrier' => [carrier1.guid, carrier2.guid, carrier3.guid, carrier4.guid, ''],
      'country' => [country1.iso2, country2.iso2]
      }), @chan.augmented_restrictions
  end

  test "clickatell channel can send a message within coverage table" do
    country = Country.make!
    carrier = Carrier.make! :country => country

    @chan.configuration[:network] = '44'
    @chan.save!

    ClickatellCoverageMO.create!(:country_id => country.id, :carrier_id => carrier.id, :network => '44', :cost => 1)

    assert @chan.can_route_ao?(ao_with(country.iso2, carrier.guid))
  end

  test "clickatell channel can send a message within coverage table only with country" do
    country = Country.make!
    carrier = Carrier.make! :country => country

    @chan.configuration[:network] = '44'
    @chan.save!

    ClickatellCoverageMO.create!(:country_id => country.id, :carrier_id => carrier.id, :network => '44', :cost => 1)

    assert @chan.can_route_ao?(ao_with(country.iso2))
  end

  test "can leave password empty for update" do
    assert_can_leave_password_empty @chan
  end

  test "can leave incoming password empty for update" do
    assert_can_leave_password_empty @chan, :incoming_password
  end

  def ao_with(country, carrier = nil)
    msg = AoMessage.new
    msg.country = country
    msg.carrier = carrier unless carrier.nil?
    msg
  end
end
