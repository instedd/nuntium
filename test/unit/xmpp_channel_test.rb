require 'test_helper'

class XmppChannelTest < ActiveSupport::TestCase
  def setup
    @chan = XmppChannel.make
  end

  [:user, :domain, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  include ServiceChannelTest
end
