require 'test_helper'

class IpopChannelTest < ActiveSupport::TestCase
  def setup
    @chan = IpopChannel.make
  end

  include GenericChannelTest

  [:mt_post_url, :bid, :cid].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
end
