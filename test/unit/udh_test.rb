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

class UdhTest < ActiveSupport::TestCase
  test "nil doesnt break" do
    udh = Udh.new(nil)
    assert_equal 0, udh.length
  end

  test "empty string doesnt break" do
    udh = Udh.new('')
    assert_equal 0, udh.length
  end

  test "from simple" do
    udh = Udh.new([5, 0, 3, 0xF5, 0x12, 0x02])
    assert_equal 5, udh.length
    assert_equal 0xF5, udh[0][:reference_number]
    assert_equal 0x12, udh[0][:part_count]
    assert_equal 0x02, udh[0][:part_number]
  end

  test "ignore other headers" do
    udh = Udh.new([6, 5, 4, 195, 80, 0, 0])
    assert_equal 6, udh.length
    assert_nil udh[0]
  end

  test "from complex" do
    udh = Udh.new([11, 8, 4, 195, 80, 0, 0, 0, 3, 245, 18, 2])
    assert_equal 11, udh.length
    assert_equal 0xF5, udh[0][:reference_number]
    assert_equal 0x12, udh[0][:part_count]
    assert_equal 0x02, udh[0][:part_number]
  end
end
