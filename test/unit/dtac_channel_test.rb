require 'test_helper'

class DtacChannelTest < ActiveSupport::TestCase
  def setup
    @chan = DtacChannel.make
  end

  [:user, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  include GenericChannelTest
end
