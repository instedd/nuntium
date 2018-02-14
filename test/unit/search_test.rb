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

class SearchTest < ActiveSupport::TestCase
  test "nil" do
    s = Search.new(nil)
    assert_nil s.search
  end

  test "simple 1" do
    s = Search.new('search')
    assert_equal 'search', s.search
  end

  test "simple 2" do
    s = Search.new('hello world')
    assert_equal 'hello world', s.search
  end

  test "with protocol" do
    s = Search.new('sms://foo')
    assert_equal 'sms://foo', s.search
  end

  test "key value" do
    s = Search.new('key:value')
    assert_nil s.search
    assert_equal 'value', s[:key]
  end

  test "key value with words" do
    s = Search.new('one key:value other:thing two')
    assert_equal 'one two', s.search
    assert_equal 'value', s[:key]
    assert_equal 'thing', s[:other]
  end

  test "key value with quotes" do
    s = Search.new('key:"more than one word"')
    assert_nil s.search
    assert_equal 'more than one word', s[:key]
  end

  test "key value with quotes twice" do
    s = Search.new('key:"more than one word" key2:"something else"')
    assert_nil s.search
    assert_equal 'more than one word', s[:key]
    assert_equal 'something else', s[:key2]
  end

  test "key value with quotes and symbols" do
    s = Search.new('key:"more than : one word"')
    assert_nil s.search
    assert_equal 'more than : one word', s[:key]
  end

  test "key value with colon" do
    s = Search.new('key:something:else')
    assert_nil s.search
    assert_equal 'something:else', s[:key]
  end

  test "key value with protocol" do
    s = Search.new('key:value://hola')
    assert_nil s.search
    assert_equal 'value://hola', s[:key]
  end

  test "quotes" do
    s = Search.new('"more than one word"')
    assert_equal '"more than one word"', s.search
  end

  test "semicolon" do
    s = Search.new(';')
    assert_equal ';', s.search
  end
end
