require 'test_helper'

class SmtpChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :smtp
  end

  [:host, :port].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "should not save if port is not a number" do
    @chan.configuration[:port] = 'foo'
    assert_false @chan.save
  end

  test "should not save if port is negative" do
    @chan.configuration[:port] = -430
    assert_false @chan.save
  end

  include GenericChannelHandlerTest
end
