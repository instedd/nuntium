require 'test_helper'
require 'mocha'

class ApplicationTest < ActiveSupport::TestCase

  include Mocha::API

  test "check modified" do
    app = Application.make
    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority - 10
    
    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'    
    assert_equal chan2.id, msg.channel_id
    
    sleep 2
    
    chan2.priority = chan1.priority + 10
    chan2.save!
    
    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'    
    assert_equal chan1.id, msg.channel_id
  end
  
  test "should create worker queue on create" do
    app = Application.make
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal "application_queue.#{app.id}", wqs[0].queue_name
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
  
    app = Application.make
    assert_same app, binded
  end
  
  test "should enqueue http post callback" do
    app = Application.make :http_post_callback
    
    msg = ATMessage.create!(:account => app.account, :subject => 'foo')
    
    Queues.expects(:publish_application).with do |a, j|
      a.id == app.id and 
        j.kind_of?(SendPostCallbackMessageJob) and 
        j.account_id == app.account.id and 
        j.application_id == app.id and
        j.message_id == msg.id 
    end
    
    app.route_at msg, nil
  end
  
  test "route ao protocol not found in message" do
    app = Application.make
  
    msg = AOMessage.make_unsaved :to => '+5678'
    app.route_ao msg, 'test'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  
    logs = AccountLog.all
    
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal app.account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "Protocol not found in 'to' field", log.message
  end
  
  test "route ao channel not found for protocol" do
    app = Application.make
  
    msg = AOMessage.make_unsaved :to => 'unknown://+5678'
    app.route_ao msg, 'test'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  
    logs = AccountLog.all
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal app.account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "No channel found for protocol 'unknown'", log.message
  end
  
  test "route select channel based on protocol" do
    app = Application.make
  
    chan1 = Channel.make :account => app.account, :protocol => 'protocol' 
    chan2 = Channel.make :account => app.account, :protocol => 'protocol2'
    
    msg = AOMessage.make_unsaved(:to => 'protocol2://Someone else')
    app.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "route ao saves mobile numbers" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country
    
    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid
    
    app.route_ao msg, 'test'
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.to.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end
  
  test "route ao does not save mobile numbers if more than one country and/or carrier" do
    app = Application.make
    
    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']
    
    app.route_ao msg, 'test'
    
    assert_equal 0, MobileNumber.count
  end
  
  test "route ao updates mobile numbers" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country
    
    MobileNumber.create!(:number => '5678', :country_id => country.id + 1)
    
    msg = AOMessage.make_unsaved :to => 'sms://+5678'
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid
    
    app.route_ao msg, 'test'
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.to.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end
  
  test "route ao filter channel because of country" do
    app = Application.make
    
    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = 'br'
    
    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = 'ar'  
    chan1.save!
    
    app.route_ao msg, 'test'
    
    assert_equal 'failed', msg.state
  end
  
  test "route ao filter channel because of country 2" do
    app = Application.make
    
    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = ['br', 'bz']
    
    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = ['ar', 'br']
    chan1.save!
    
    app.route_ao msg, 'test'
    
    assert_equal 'queued', msg.state
  end
  
  test "route ao use last channel" do
    app = Application.make
    
    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10
    
    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan2.id, :address => '5678' 
    
    msg = AOMessage.make_unsaved :to => 'sms://+5678'
    app.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "route ao use suggested channel" do
    app = Application.make
    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10
    
    msg = AOMessage.make_unsaved
    msg.suggested_channel = chan2.name
    app.route_ao msg, 'test'
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "route ao infer country" do
    app = Application.make
    chan = Channel.make :account => app.account
    country = Country.make
    
    msg = AOMessage.make_unsaved :to => "sms://+#{country.phone_prefix}1234"
    app.route_ao msg, 'test'
    
    assert_equal country.iso2, msg.country
  end
  
  test "route ao broadcast" do
    app = Application.make :broadcast
    
    chans = [Channel.make(:account => app.account), Channel.make(:account => app.account)]
    
    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'
    
    assert_nil msg.channel
    assert_equal 'broadcasted', msg.state
    
    children = AOMessage.all :conditions => ['parent_id = ?', msg.id]
    assert_equal 2, children.length
    
    2.times do |i|
      assert_equal chans[i], children[i].channel
      assert_equal msg.id, children[i].parent_id
      assert_not_nil children[i].guid
      assert_not_equal children[i].guid, msg.guid
    end
  end
  
  test "route ao broadcast override" do
    app = Application.make
    
    chans = [Channel.make(:account => app.account), Channel.make(:account => app.account)]
    
    msg = AOMessage.make_unsaved
    msg.strategy = 'broadcast'
    app.route_ao msg, 'test'
    
    assert_equal 'broadcasted', msg.state
  end
  
end
