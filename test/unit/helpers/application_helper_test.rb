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

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper

  test "short for nil" do
    assert_equal '', short(nil)
  end
  
  test "short for short string" do
    assert_equal 'hello', short('hello', 8)
  end
  
  test "short for long string" do
    assert_equal 'hello wo...', short('hello world', 8)
  end
end