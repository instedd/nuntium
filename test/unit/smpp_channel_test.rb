require 'test_helper'

class SmppChannelTest < ActiveSupport::TestCase
  def setup
    @chan = SmppChannel.make
  end

  [:host, :port, :source_ton, :source_npi, :destination_ton, :destination_npi, :user, :password, :mt_csms_method].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "suspension codes as array" do
    @chan.suspension_codes = '1, 2, a'
    assert_equal [1, 2], @chan.suspension_codes_as_array
  end

  test "rejection codes as array" do
    @chan.rejection_codes = '1, 2, a'
    assert_equal [1, 2], @chan.rejection_codes_as_array
  end

  include ServiceChannelTest
end
