require 'test_helper'
require 'mocha'

class AOMessageTest < ActiveSupport::TestCase
  include Mocha::API

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
  
  test "infer attributes one carrier" do
    arg = Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
    Carrier.create! :country_id => arg.id, :name => 'Personal', :prefixes => '34, 56', :guid => 'personal'  
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes
    
    assert_equal 'ar', msg.country
    assert_equal 'personal', msg.carrier
  end

  test "infer attributes two carriers" do
    arg = Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
    Carrier.create! :country_id => arg.id, :name => 'Personal', :prefixes => '34, 56', :guid => 'personal'  
    Carrier.create! :country_id => arg.id, :name => 'Movistar', :prefixes => '3', :guid => 'movistar'
    Carrier.create! :country_id => arg.id, :name => 'Claro', :prefixes => '4', :guid => 'claro'
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes
    
    assert_equal 'ar', msg.country
    assert_equal Set.new(['personal', 'movistar']), Set.new(msg.carrier)
  end
  
  test "don't infer carrier if present" do
    arg = Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 => 'arg', :phone_prefix => '12'
    Carrier.create! :country_id => arg.id, :name => 'Personal', :prefixes => '34, 56', :guid => 'personal'  
  
    msg = AOMessage.new(:to => 'sms://+1234')
    msg.country = 'ar'
    msg.carrier = 'movistar'
    msg.infer_custom_attributes
    
    assert_equal 'ar', msg.country
    assert_equal 'movistar', msg.carrier
  end
  
  ['failed', 'confirmed', 'delivered'].each do |state|
    test "delivery ack when #{state}" do
      account = Account.create! :name => 'foo', :password => 'bar'
      app = create_app account
      app.delivery_ack_method = 'get'
      app.delivery_ack_url = 'foo'
      app.save!
      chan = new_channel account, 'chan1'
      
      msg = AOMessage.new(:account_id => account.id, :application_id => app.id, :channel_id => chan.id, :guid => 'SomeGuid', :state => 'pending')
      msg.save!
      
      Queues.expects(:publish_application).with do |a, j|
        a.id == account.id and 
          j.kind_of?(SendDeliveryAckJob) and 
          j.account_id == account.id and 
          j.application_id == app.id and 
          j.message_id == msg.id and
          j.state == state
      end
      
      msg.state = state
      msg.save!
    end
  end
  
  test "don't delivery ack when queued" do
    account = Account.create! :name => 'foo', :password => 'bar'
    app = create_app account
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = new_channel account, 'chan1'
    
    msg = AOMessage.new(:account_id => account.id, :application_id => app.id, :channel_id => chan.id, :guid => 'SomeGuid', :state => 'pending')
    msg.save!
    
    Queues.expects(:publish_application).times(0)
    
    msg.state = 'queued'
    msg.save!
  end
  
  test "don't delivery ack when method is none" do
    account = Account.create! :name => 'foo', :password => 'bar'
    app = create_app account
    app.delivery_ack_method = 'none'
    app.save!
    chan = new_channel account, 'chan1'
    
    msg = AOMessage.new(:account_id => account.id, :application_id => app.id, :channel_id => chan.id, :guid => 'SomeGuid', :state => 'pending')
    msg.save!
    
    Queues.expects(:publish_application).times(0)
    
    msg.state = 'failed'
    msg.save!
  end
end
