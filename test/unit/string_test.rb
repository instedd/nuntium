require 'test_helper'

class StringTest < ActiveSupport::TestCase
  test "to.protocol" do
    msg = AOMessage.new(:to => 'sms://something')
    assert_equal 'sms', msg.to.protocol
  end
  
  test "to.protocol nil" do
    msg = AOMessage.new(:to => 'something')
    assert_equal '', msg.to.protocol
  end
  
  test "to.without_protocol nil" do
    msg = AOMessage.new(:to => 'sms://something')
    assert_equal 'something', msg.to.without_protocol
  end
  
  test "from.protocol" do
    msg = AOMessage.new(:from => 'sms://something')
    assert_equal 'sms', msg.from.protocol
  end
  
  test "from.protocol nil" do
    msg = AOMessage.new(:from => 'something')
    assert_equal '', msg.from.protocol
  end
  
  test "from.without_protocol nil" do
    msg = AOMessage.new(:from => 'sms://something')
    assert_equal 'something', msg.from.without_protocol
  end
  
  test "starts with" do
    assert_true 'HolaATodos'.starts_with?('Hola')
    assert_false 'HolaATodos'.starts_with?('HolaT')
  end
end
