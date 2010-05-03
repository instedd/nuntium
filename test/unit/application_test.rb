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
    application.configuration = {:interface_url => 'foo', :interface_user => 'bar', :interface_password => 'baz'}
    application.save!
    
    msg = ATMessage.create!(:account => application.account, :subject => 'foo')
    
    Queues.expects(:publish_application).with do |a, j|
      a.id == application.id and 
        j.kind_of?(SendPostCallbackMessageJob) and 
        j.account_id == application.account.id and 
        j.application_id == application.id and
        j.message_id == msg.id 
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
  
  test "ao routing does not save mobile numbers if more than one country and/or carrier" do
    app = create_app @account
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']
    
    app.route_ao msg, 'test'
    
    assert_equal 0, MobileNumber.count
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
    
    chan1 = new_channel @account, 'chan1'
    chan1.restrictions['country'] = 'ar'  
    chan1.save!
    
    app.route_ao msg, 'test'
    
    assert_equal 'failed', msg.state
  end
  
  test "ao routing filter channel because of country 2" do
    app = create_app @account
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = ['br', 'bz']
    
    chan1 = new_channel @account, 'chan1'
    chan1.restrictions['country'] = ['ar', 'br']
    chan1.save!
    
    app.route_ao msg, 'test'
    
    assert_equal 'queued', msg.state
  end
  
  test "ao routing use last channel" do
    app = create_app @account
    app.use_address_source = true
    app.save!
    
    chan1 = new_channel @account, 'chan1'
    chan2 = new_channel @account, 'chan2'
    
    chan1.priority = chan2.priority - 10
    chan1.save!
    
    AddressSource.create! :account_id => @account.id, :application_id => app.id, :channel_id => chan2.id, :address => '5678' 
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    app.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "ao routing use suggested channel" do
    app = create_app @account
    chan1 = new_channel @account, 'chan1'
    chan2 = new_channel @account, 'chan2'
    
    chan1.priority = chan2.priority - 10
    chan1.save!
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5678', :subject => 'foo', :body => 'bar'
    msg.suggested_channel = 'chan2'
    app.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "ao routing infer country" do
    app = create_app @account
    chan1 = new_channel @account, 'chan1'
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5478', :subject => 'foo', :body => 'bar'
    app.route_ao msg, 'test'
    
    assert_equal 'ar', msg.country
  end
  
  test "broadcast" do
    app = create_app @account
    app.strategy = 'broadcast'
    app.save!
    
    chans = [new_channel(@account, 'chan1'), new_channel(@account, 'chan2')]
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5478', :subject => 'foo', :body => 'bar', :guid => 'SoemGuid'
    app.route_ao msg, 'test'
    
    assert_nil msg.channel
    assert_equal 'broadcasted', msg.state
    
    children = AOMessage.all :conditions => ['parent_id = ?', msg.id]
    assert_equal 2, children.length
    
    [0, 1].each do |i|
      assert_equal chans[i], children[i].channel
      assert_equal msg.id, children[i].parent_id
      assert_not_nil children[i].guid
      assert_not_equal children[i].guid, msg.guid
    end
  end
  
  test "broadcast override" do
    app = create_app @account
    app.strategy = 'single_priority'
    app.save!
    
    chans = [new_channel(@account, 'chan1'), new_channel(@account, 'chan2')]
    
    msg = AOMessage.new :from => 'sms://1234', :to => 'sms://+5478', :subject => 'foo', :body => 'bar', :guid => 'SoemGuid'
    msg.strategy = 'broadcast'
    app.route_ao msg, 'test'
    
    assert_equal 'broadcasted', msg.state
  end
  
end
