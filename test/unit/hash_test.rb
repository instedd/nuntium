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
