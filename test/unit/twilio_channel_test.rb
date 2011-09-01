require 'test_helper'

class TwilioChannelTest < ActiveSupport::TestCase
  def setup
    @chan = TwilioChannel.make
  end

  include GenericChannelTest

  [:account_sid, :auth_token, :from, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
end
