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

  include ServiceChannelTest
end
