require 'test_helper'
require 'mocha'

class ApplicationTest < ActiveSupport::TestCase

  include Mocha::API
  
  def setup
    @account = Account.create!({:name => 'foo', :password => 'pass'})
    @country = Country.create!(:name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54')
    @carrier = Carrier.create!(:country => @country, :name => 'Personal', :guid => "ABC123", :prefixes => '1, 2, 3')
  end

  test "check modified" do
    application = Application.create!(:account_id => @account.id, :name => 'application1', :interface => 'rss', :password => 'foo')
    
    chan1 = new_channel application.account, 'Uno'
    chan2 = new_channel application.account, 'Dos'
    chan2.priority = chan1.priority - 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    application.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
    
    sleep 2
    
    chan2.priority = chan1.priority + 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    application.route_ao msg, 'test'
    
    assert_equal chan1.id, msg.channel_id
  end
  
  test "should create worker queue on create" do
    application = Application.create!(:account_id => @account.id, :name => 'application1', :interface => 'rss', :password => 'foo')
    
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal "application_queue.#{application.id}", wqs[0].queue_name
    assert_equal "fast", wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "should bind queue on create" do
    binded = nil
  
    Queues.expects(:bind_application).with do |a|
      binded = a
      true
    end
  
    application = Application.create!(:account_id => @account.id, :name => 'application1', :interface => 'rss', :password => 'foo')
    
    assert_same application, binded
  end
  
  test "should enqueue http post callback" do
    application = Application.new(:account_id => @account.id, :name => 'application1', :interface => 'http_post_callback', :password => 'foo')
    application.configuration = {:url => 'foo', :user => 'bar', :password => 'baz'}
    application.save!
    
    msg = ATMessage.create!(:account => application.account, :subject => 'foo')
    
    Queues.expects(:publish_application) do |a, j|
      a.id == account.id and j.kind_of?(SendPostCallbackMessageJob) and j.account_id == application.account.id and j.message_id == msg.id 
    end
    
    application.route_at msg, nil
  end
  
  test "ao routing saves mobile numbers" do
    app = create_app @account
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = 'ar'
    msg.custom_attributes['carrier'] = 'ABC123'
    
    app.route_ao msg, 'test'
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal '5678', nums[0].number
    assert_equal @country.id, nums[0].country_id
    assert_equal @carrier.id, nums[0].carrier_id
  end
  
  test "ao routing updates mobile numbers" do
    app = create_app @account
    
    MobileNumber.create!(:number => '5678', :country_id => 2)
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = 'ar'
    msg.custom_attributes['carrier'] = 'ABC123'
    
    app.route_ao msg, 'test'
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal '5678', nums[0].number
    assert_equal @country.id, nums[0].country_id
    assert_equal @carrier.id, nums[0].carrier_id
  end
  
  test "ao routing filter channel because of country" do
    app = create_app @account
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = 'br'
    
    chan1 = create_channel @account, 'chan1', 'pass1', 'twitter', 'sms'
    chan1.custom_attributes['country'] = 'ar'  
    chan1.save! 
    
    app.route_ao msg, 'test'
    
    assert_equal 'error', msg.state
  end
  
  test "ao routing filter channel because of country 2" do
    app = create_app @account
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = ['br', 'bz']
    
    chan1 = create_channel @account, 'chan1', 'pass1', 'twitter', 'sms'
    chan1.custom_attributes['country'] = ['ar', 'br']
    chan1.save!
    
    app.route_ao msg, 'test'
    
    assert_equal 'queued', msg.state
  end
  
end
