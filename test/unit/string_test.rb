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

  test "mobile_number" do
    assert_equal '1234', 'sms://1234'.mobile_number
    assert_equal '1234', 'sms://+1234'.mobile_number
    assert_equal '1234', '+1234'.mobile_number
  end

  test "protocol and address" do
    assert_equal ['sms', '1234'], 'sms://1234'.protocol_and_address
    assert_equal ['', '1234'], '1234'.protocol_and_address
    assert_equal ['sms', ''], 'sms://'.protocol_and_address
  end

  test "valid sms address" do
    assert_true "sms://1234".valid_address?
    assert_true "sms://+1234".valid_address?
    assert_false "sms://foo".valid_address?
    assert_false "sms://+foo".valid_address?
    assert_false "sms://".valid_address?
    assert_false "sms:// ".valid_address?
    assert_false "sms:// 123".valid_address?
    assert_false "sms://123 4".valid_address?
  end

  test "valid email address" do
    assert_true "mailto://foo@bar.com".valid_address?
    assert_true "mailto://foo.bar+baz@example.com".valid_address?
    assert_false "mailto://foo".valid_address?
    assert_false "mailto://!()@foo.com".valid_address?
    assert_false "mailto://%$\#@foo.com".valid_address?
    assert_false "mailto://".valid_address?
    assert_false "mailto:// ".valid_address?
    assert_false "mailto:// foo@bar.com".valid_address?
  end

end
