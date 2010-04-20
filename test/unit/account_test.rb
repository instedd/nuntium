require 'test_helper'
require 'mocha'

class AccountTest < ActiveSupport::TestCase

  include Mocha::API

  test "should not save if name is blank" do
    account = Account.new(:password => 'foo')
    assert !account.save
  end
  
  test "should not save if password is blank" do
    account = Account.new(:name => 'account')
    assert !account.save
  end
  
  test "should not save if password confirmation fails" do
    account = Account.new(:name => 'account', :password => 'foo', :password_confirmation => 'foo2')
    assert !account.save
  end
  
  test "should not save if name is taken" do
    Account.create!(:name => 'account', :password => 'foo')
    account = Account.new(:name => 'account', :password => 'foo2')
    assert !account.save
  end
  
  test "should save account" do
    account = Account.new(:name => 'account', :password => 'foo', :password_confirmation => 'foo')
    assert account.save
  end
  
  test "should find by name" do
    account1 = Account.create!(:name => 'account', :password => 'foo')
    account2 = Account.find_by_name 'account'
    assert_equal account1.id, account2.id
  end
  
  test "should authenticate" do
    account1 = Account.create!(:name => 'account', :password => 'foo')
    assert account1.authenticate('foo')
    assert !account1.authenticate('foo2')
  end
  
  test "should find by id if numerical" do
    account = Account.create!(:name => 'account', :password => 'foo')
    found = Account.find_by_id_or_name(account.id.to_s)
    assert_equal account, found
  end
  
  test "should find by name if string" do
    account = Account.create!(:name => 'account2', :password => 'foo')
    found = Account.find_by_id_or_name('account2')
    assert_equal account, found
  end
  
  test "ao routing change from" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'sms://1234'"
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal 'sms://1234', msg.from
    
    msg = AOMessage.all[0]
    assert_equal 'sms://1234', msg.from
  end
  
  test "ao routing change from twice" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'sms://1234'"
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal 2, AOMessage.all.length
    
    assert_equal 'sms://1234', msg.from
  end
  
  test "ao routing select channel by name" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    
    account.configuration[:ao_routing] = "msg.route_to_channel 'Dos'"
    account.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan2.id, qsts[0].channel_id
  end
  
  test "ao routing select channel by array" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    chan3 = new_channel account, 'Tres'
    chan3.metric = chan1.metric + 90
    chan3.save!
    
    account.configuration[:ao_routing] = "msg.route_to_any_channel 'Dos', 'Tres'"
    account.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing change account" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.save!
    
    account2 = Account.create!(:name => 'account2', :password => 'foo')
    
    chan1 = new_channel account1, 'Uno'
    chan2 = new_channel account1, 'Dos'
    chan3 = new_channel account2, 'Tres'
    
    account1.configuration[:ao_routing] = "msg.route_to_account 'account2'"
    account1.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account1.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing copy in two channels" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.save!
    
    account2 = Account.create!(:name => 'account2', :password => 'foo')
    
    chan1 = new_channel account1, 'Uno'
    chan2 = new_channel account1, 'Dos'
    
    account1.configuration[:ao_routing] = "msg.copy{|x| x.from = 'UNO'; x.route_to_channel 'Uno'}; msg.copy{|x| x.from = 'DOS'; x.route_to_channel 'Dos'};"
    account1.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    account1.route(msg, 'test')
    
    msgs = AOMessage.all
    assert_equal 2, msgs.length
    assert_equal 'UNO', msgs[0].from
    assert_equal 'DOS', msgs[1].from
    
    qsts = QSTOutgoingMessage.all
    assert_equal 2, qsts.length
    assert_equal chan1.id, qsts[0].channel_id
    assert_equal chan2.id, qsts[1].channel_id
  end
  
  test "ao routing route to any channel test passes" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'bar'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'bar'})" 
    assert_true account.save
  end
  
  test "ao routing route to any channel test fails" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'bar'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'baZ'})" 
    assert_false account.save
  end
  
  test "ao routing route to any channel test passes with comments in the end" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'bar'
    #comment"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'bar'})
    #comment" 
    assert_true account.save

    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')    
    account.route msg, 'test'
    assert_equal 'bar', AOMessage.all[0].from
  end
  
  test "ao routing route to any channel explicit test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Uno')" 
    assert_true account.save
  end
  
  test "ao routing route to any channel explicit test fails" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Dos')" 
    assert_false account.save
  end
  
  test "ao routing route to any channel explicit test fails many" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno', 'Dos'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Dos')" 
    assert_false account.save
  end
  
  test "ao routing route to any channel explicit and change from test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_any_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'bar'}, 'Uno')" 
    assert_true account.save
  end
  
  test "ao routing route to any channel explicit and change from test fails" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_any_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'foo'}, 'Uno')" 
    assert_false account.save
  end
  
  test "ao routing route to channel test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.route_to_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, 'Uno')" 
    assert_true account.save
  end
  
  test "ao routing route to channel test fails" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.route_to_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, 'Dos')" 
    assert_false account.save
  end
  
  test "ao routing route to channel and change from test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, {:from => 'bar'}, 'Uno')" 
    assert_true account.save
  end
  
  test "ao routing route to channel and change from test fails" do
    account = Account.create!(:name => 'account', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_channel 'Uno'"
    account.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, {:from => 'foo'}, 'Uno')" 
    assert_false account.save
  end
  
  test "ao routing route to account test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.route_to_account 'account'"
    account.configuration[:ao_routing_test] = "assert.routed_to_account({:from => 'foo'}, 'account')" 
    assert_true account.save
  end
  
  test "ao routing route to account test fails" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.route_to_account 'account'"
    account.configuration[:ao_routing_test] = "assert.routed_to_account({:from => 'foo'}, 'account2')" 
    assert_false account.save
  end
  
  test "ao routing route to account and change from test passes" do
    account = Account.create!(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_account 'account'"
    account.configuration[:ao_routing_test] = "assert.routed_to_account({:from => 'foo'}, {:from => 'bar'}, 'account')" 
    assert_true account.save
  end
  
  test "ao routing route to account and change from test fails" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_account 'account'"
    account.configuration[:ao_routing_test] = "assert.routed_to_account({:from => 'foo'}, {:from => 'foo'}, 'account')" 
    assert_false account.save
  end
  
  test "ao routing route same message twice fails" do
    account = Account.new(:name => 'account', :password => 'foo')
    account.configuration[:ao_routing] = "msg.route_to_channel 'one'; msg.route_to_account 'account'"
    account.configuration[:ao_routing_test] = "assert.routed_to_account({}, {}, 'account')" 
    assert_false account.save
  end
  
  test "at routing" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.configuration[:at_routing] = "msg.from = 'foo'"
    account1.save!
    
    chan = new_channel account1, 'Uno'
    
    msg = ATMessage.new(:account_id => account1.id, :from => 'bar')
    account1.accept msg, chan    
    
    assert_equal 'foo', msg.from
    assert_equal 'foo', ATMessage.all[0].from
  end
  
  test "at routing change account" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.configuration[:at_routing] = "msg.account = Account.find_by_name 'account2'"
    account1.save!
    
    account2 = Account.create!(:name => 'account2', :password => 'foo')
    
    chan = new_channel account1, 'Uno'
    
    msg = ATMessage.new(:account_id => account1.id, :from => 'bar')
    account1.accept msg, chan    
    
    assert_equal account2.id, ATMessage.all[0].account_id
  end
  
  test "at routing test passes" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.configuration[:at_routing] = "msg.from = 'foo'"
    account1.configuration[:at_routing_test] = "assert.transform({:from => 'bar'}, {:from => 'foo'})"
    assert_true account1.save
  end
  
  test "at routing test fails" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.configuration[:at_routing] = "msg.from = 'foo'"
    account1.configuration[:at_routing_test] = "assert.transform({:from => 'bar'}, {:from => 'bar'})"
    assert_false account1.save
  end
  
  test "at routing test passes with comments" do
    account1 = Account.new(:name => 'account1', :password => 'foo')
    account1.configuration[:at_routing] = "msg.from = 'foo'
    #comment"
    account1.configuration[:at_routing_test] = "assert.transform({:from => 'bar'}, {:from => 'foo'})
    #comment"
    assert_true account1.save
    
    chan1 = new_channel account1, 'Uno'
    account1.accept ATMessage.new, chan1
    assert_equal 'foo', ATMessage.first.from
  end
  
  test "at routing inspect channel in test passes" do
    account1 = Account.create!(:name => 'account1', :password => 'foo')
    chan1 = new_channel account1, 'Uno'
    chan2 = new_channel account1, 'Dos'
    
    account1.configuration[:at_routing] = "if !msg.channel.nil? && msg.channel.name == 'Uno'; msg.from = 'bar'; end;"
    account1.configuration[:at_routing_test] = "assert.transform({:from => 'to'}, {:from => 'bar'}, 'Uno')"
    assert_true account1.save
  end
  
  test "at routing inspect channel in test fails" do
    account1 = Account.create!(:name => 'account1', :password => 'foo')
    chan1 = new_channel account1, 'Uno'
    chan2 = new_channel account1, 'Dos'
    
    account1.configuration[:at_routing] = "if !msg.channel.nil? && msg.channel.name == 'Uno'; msg.from = 'bar'; end;"
    account1.configuration[:at_routing_test] = "assert.transform({:from => 'to'}, {:from => 'foo'}, 'Uno')"
    assert_false account1.save
  end
  
  test "at routing doesn't create address source" do
    account = Account.create!(:name => 'account1', :password => 'foo')
    chan = new_channel account, 'Uno'
    
    msg = ATMessage.new(:account_id => account.id, :from => 'bar')
    account.accept msg, chan
    
    assert_equal 0, AddressSource.all.length
  end
  
  test "at routing creates address source" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.configuration[:use_address_source] = 1
    account.save!
    
    chan = new_channel account, 'Uno'
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan
    
    ass = AddressSource.all
    assert_equal 1, ass.length
    
    as = ass[0]
    assert_equal account.id, as.account_id
    assert_equal 'sms://1234', as.address
    assert_equal chan.id, as.channel_id
  end
  
  test "at routing overrides address source" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.configuration[:use_address_source] = 1
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan1
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan2
    
    ass = AddressSource.all
    assert_equal 1, ass.length
    
    as = ass[0]
    assert_equal account.id, as.account_id
    assert_equal 'sms://1234', as.address
    assert_equal chan2.id, as.channel_id
  end
  
  test "ao routing uses address source" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.configuration[:use_address_source] = 1
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric - 10
    chan2.save!
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan1
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1234', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal chan1.id, msg.channel_id
  end
  
  test "ao routing does not use address source" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.configuration[:use_address_source] = 1
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric - 10
    chan2.save!
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan1
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "ao routing test with address source" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.configuration[:use_address_source] = 1
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric - 10
    chan2.save!
    
    account.configuration[:ao_routing] = "if !preferred_channel.nil?; msg.route_to_channel preferred_channel; else; msg.route_to_channel 'Dos'; end;"
    account.configuration[:ao_routing_test] = "assert.routed_to_channel({:preferred_channel => 'Uno'}, {}, 'Uno')"
    account.save!
    
    msg = ATMessage.new(:account_id => account.id, :from => 'sms://1234')
    account.accept msg, chan1
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal chan2.id, msg.channel_id
  end
  
  test "check modified" do
    account = Account.new(:name => 'account1', :password => 'foo')
    account.save!
    
    chan1 = new_channel account, 'Uno'
    chan2 = new_channel account, 'Dos'
    chan2.metric = chan1.metric - 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal chan2.id, msg.channel_id
    
    sleep 1
    
    chan2.metric = chan1.metric + 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    account.route(msg, 'test')
    
    assert_equal chan1.id, msg.channel_id
  end
  
  test "should create worker queue on create" do
    account = Account.create!(:name => 'account1', :password => 'foo')
    
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal "account_queue.#{account.id}", wqs[0].queue_name
    assert_equal "fast", wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "should bind queue on create" do
    binded = nil
  
    Queues.expects(:bind_account).with do |a|
      binded = a
      true
    end
  
    account = Account.create!(:name => 'account1', :password => 'foo')
    
    assert_same account, binded
  end
  
  test "should enqueue http post callback" do
    account = Account.create!(:name => 'account1', :password => 'foo', :interface => 'http_post_callback')
    msg = ATMessage.create!(:account => account, :subject => 'foo')
    
    Queues.expects(:publish_account) do |a, j|
      a.id == account.id and j.kind_of?(SendPostCallbackMessageJob) and j.account_id == account.id and j.message_id == msg.id 
    end
    
    account.accept msg, 'ui'
  end
  
end
