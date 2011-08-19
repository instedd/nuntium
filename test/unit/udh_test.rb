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
    udh = Udh.new("\x05\x00\x03\xf5\x12\x02")
    assert_equal 5, udh.length
    assert_equal 0xF5, udh[0][:reference_number]
    assert_equal 0x12, udh[0][:part_count]
    assert_equal 0x02, udh[0][:part_number]
  end

  test "ignore other headers" do
    udh = Udh.new("\x06\x05\x04\xc3\x50\x00\x00")
    assert_equal 6, udh.length
    assert_nil udh[0]
  end

  test "from complex" do
    udh = Udh.new("\x0b\x08\x04\xc3\x50\x00\x00\x00\x03\xf5\x12\x02")
    assert_equal 11, udh.length
    assert_equal 0xF5, udh[0][:reference_number]
    assert_equal 0x12, udh[0][:part_count]
    assert_equal 0x02, udh[0][:part_number]
  end

  test "skip" do
    udh = Udh.new("\x0b\x08\x04\xc3\x50\x00\x00\x00\x03\xf5\x12\x02hello")
    assert_equal 'hello', udh.skip("\x0b\x08\x04\xc3\x50\x00\x00\x00\x03\xf5\x12\x02hello")
  end
end
