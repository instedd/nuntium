require 'test_helper'

class AOMessageTest < ActiveSupport::TestCase
  test "subject and body no subject nor body" do
    msg = AOMessage.new()
    assert_equal '', msg.subject_and_body
  end
  
  test "subject and body just subject" do
    msg = AOMessage.new(:subject => 'subject')
    assert_equal 'subject', msg.subject_and_body
  end
  
  test "subject and body just body" do
    msg = AOMessage.new(:body => 'body')
    assert_equal 'body', msg.subject_and_body
  end
  
  test "subject and body" do
    msg = AOMessage.new(:subject => 'subject', :body => 'body')
    assert_equal 'subject - body', msg.subject_and_body
  end
  
  test "to_protocol" do
    msg = AOMessage.new(:to => 'sms://something')
    assert_equal 'sms', msg.to_protocol
  end
  
  test "to_protocol nil" do
    msg = AOMessage.new(:to => 'something')
    assert_nil msg.to_protocol
  end
  
  test "to_without_protocol nil" do
    msg = AOMessage.new(:to => 'sms://something')
    assert_equal 'something', msg.to_without_protocol
  end
  
  test "from_protocol" do
    msg = AOMessage.new(:from => 'sms://something')
    assert_equal 'sms', msg.from_protocol
  end
  
  test "from_protocol nil" do
    msg = AOMessage.new(:from => 'something')
    assert_nil msg.from_protocol
  end
  
  test "from_without_protocol nil" do
    msg = AOMessage.new(:from => 'sms://something')
    assert_equal 'something', msg.from_without_protocol
  end
end
