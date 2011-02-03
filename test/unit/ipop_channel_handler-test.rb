require 'test_helper'

class IpopChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :ipop
  end

  include GenericChannelHandlerTest

  [:mt_post_url, :bid, :cid].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
end
