require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  test "nil" do
    s = Search.new(nil)
    assert_equal nil, s.search
  end

  test "simple 1" do
    s = Search.new('search')
    assert_equal 'search', s.search
  end
  
  test "simple 2" do
    s = Search.new('hello world')
    assert_equal 'hello world', s.search
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
  
  test "quotes" do
    s = Search.new('"more than one word"')
    assert_equal '"more than one word"', s.search
  end
  
  test "semicolon" do
    s = Search.new(';')
    assert_equal ';', s.search
  end
end
