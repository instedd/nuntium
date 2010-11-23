require 'test_helper'

class DtacChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :dtac
  end

  [:user, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  include GenericChannelHandlerTest

end
