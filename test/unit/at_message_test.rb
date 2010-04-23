require 'test_helper'

class ATMessageTest < ActiveSupport::TestCase
  test "at rules context include common fiels and custom attributes" do
    msg = ATMessage.new :from => 'a', :to => 'b', :subject => 'c', :body => 'd'
    msg.custom_attributes = { :ca1 => 'e', :ca2 => 'f' }
    
    context = msg.rules_context
    
    assert_equal 'a', context[:from]
    assert_equal 'b', context[:to]
    assert_equal 'c', context[:subject]
    assert_equal 'd', context[:body]
    assert_equal 'e', context[:ca1]
    assert_equal 'f', context[:ca2]
  end
  
  test "merge attributes recognize wellknown fields and custom attributes" do
    msg = ATMessage.new   
    attributes = { :from => 'a', :to => 'b', :subject => 'c', :body => 'd', :ca1 => 'e', :ca2 => 'f' }
    
    msg.merge attributes
    
    assert_equal 'a', msg.from
    assert_equal 'b', msg.to
    assert_equal 'c', msg.subject
    assert_equal 'd', msg.body
    assert_equal 'e', msg.custom_attributes[:ca1]
    assert_equal 'f', msg.custom_attributes[:ca2]
  end
end