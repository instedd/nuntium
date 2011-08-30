require 'test_helper'

class TwilioChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :twilio
  end

  include GenericChannelHandlerTest

  [:account_sid, :auth_token, :from, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
end
