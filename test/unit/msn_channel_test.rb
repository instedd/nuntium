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

class MsnChannelTest < ActiveSupport::TestCase
  def setup
    @chan = MsnChannel.make!
  end

  [:email].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "should validate configuration presence of password" do
    @chan = MsnChannel.make
    assert_validates_configuration_presence_of @chan, :password
  end

  test "can leave password empty for update" do
    assert_can_leave_password_empty @chan
  end

  include ServiceChannelTest
end
