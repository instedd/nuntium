require 'test_helper'
require 'mq'

class SmppChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :smpp
  end

  [:host, :port, :source_ton, :source_npi, :destination_ton, :destination_npi, :user, :password, :system_type, :mt_csms_method].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  include ServiceChannelHandlerTest
end
