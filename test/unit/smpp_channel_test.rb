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

class SmppChannelTest < ActiveSupport::TestCase
  def setup
    @chan = SmppChannel.make
  end

  [:host, :port, :source_ton, :source_npi, :destination_ton, :destination_npi, :user, :password, :mt_csms_method].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "suspension codes as array" do
    @chan.suspension_codes = '1, 2, a'
    assert_equal [1, 2], @chan.suspension_codes_as_array
  end

  test "rejection codes as array" do
    @chan.rejection_codes = '1, 2, a'
    assert_equal [1, 2], @chan.rejection_codes_as_array
  end

  test "can leave password empty for update" do
    assert_can_leave_password_empty @chan
  end

  include ServiceChannelTest
end
