require 'test_helper'

class ClickatellUdhTest < ActiveSupport::TestCase
  test "empty string returns false" do
    udh = ClickatellUdh.from_string('')
    assert_false udh
  end
  
  test "from simple" do
    udh = ClickatellUdh.from_string('050003f51202')
    assert_equal 0xF5, udh.reference_number
    assert_equal 0x12, udh.part_count
    assert_equal 0x02, udh.part_number
  end
  
  test "ignore other headers" do
    udh = ClickatellUdh.from_string('060504c3500000')
    assert_false udh
  end
  
  test "from complex" do
    udh = ClickatellUdh.from_string('0b0504c35000000003f51202')
    assert_equal 0xF5, udh.reference_number
    assert_equal 0x12, udh.part_count
    assert_equal 0x02, udh.part_number
  end
end