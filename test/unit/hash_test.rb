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

class HashTest < ActiveSupport::TestCase

  test "store multivalue" do
    h = Hash.new

    h.store_multivalue 'x', 'a'
    assert_equal 'a', h['x']

    h.store_multivalue 'x', 'b'
    assert_equal ['a', 'b'], h['x']

    h.store_multivalue 'x', 'c'
    assert_equal ['a', 'b', 'c'], h['x']
  end

  test "each multivalue single" do
     h = Hash.new
     h.store_multivalue 'x', 'a'

     h.each_multivalue do |key, values|
      assert_equal 'x', key
      assert_equal ['a'], values
     end
  end

  test "each multivalue multi" do
     h = Hash.new
     h.store_multivalue 'x', 'a'
     h.store_multivalue 'x', 'b'

     h.each_multivalue do |key, values|
      assert_equal 'x', key
      assert_equal ['a', 'b'], values
     end
  end

end
