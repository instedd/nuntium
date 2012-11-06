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

class IntegerTest < ActiveSupport::TestCase
  test "as exponential backoff" do
    assert_equal 1, 1.as_exponential_backoff
    assert_equal 1, 2.as_exponential_backoff
    assert_equal 5, 3.as_exponential_backoff
    assert_equal 5, 4.as_exponential_backoff
    assert_equal 5, 5.as_exponential_backoff
    assert_equal 15, 6.as_exponential_backoff
    assert_equal 30, 7.as_exponential_backoff
    assert_equal 30, 1000.as_exponential_backoff
  end
end
