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
