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
  
  test "to.protocol" do
    msg = AOMessage.new(:to => 'sms://something')
    assert_equal 'sms', msg.to.protocol
  end
  
  test "to.protocol nil" do
    msg = AOMessage.new(:to => 'something')
    assert_nil msg.to.protocol
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
    assert_nil msg.from.protocol
  end
  
  test "from.without_protocol nil" do
    msg = AOMessage.new(:from => 'sms://something')
    assert_equal 'something', msg.from.without_protocol
  end
end
