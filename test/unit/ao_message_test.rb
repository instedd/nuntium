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
  
  test "infer attributes none" do
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes
    
    assert_nil msg.country
    assert_nil msg.carrier
  end
  
  test "infer attributes one country" do
    Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes
    
    assert_equal 'ar', msg.country
    assert_nil msg.carrier
  end

  test "infer attributes two countries" do
    Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
    Country.create! :name => 'Brazil', :iso2 => 'br', :iso3 => 'ba', :phone_prefix => '1'
    Country.create! :name => 'Chile', :iso2 => 'ch', :iso3 => 'chi', :phone_prefix => '2'
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes
    
    assert_equal ['ar', 'br'], msg.country
    assert_nil msg.carrier
  end
  
  test "don't infer country if already specified" do
    Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.country = 'br'
    msg.infer_custom_attributes
    
    assert_equal 'br', msg.country
    assert_nil msg.carrier
  end
end
