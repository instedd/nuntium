require 'test_helper'

class TwitterChannelTest < ActiveSupport::TestCase
  def setup
    @chan = TwitterChannel.make
  end

  include GenericChannelTest
end
