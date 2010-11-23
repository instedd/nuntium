require 'test_helper'
require 'mq'

class XmppChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :xmpp
  end

  [:user, :domain, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  include ServiceChannelHandlerTest
end
