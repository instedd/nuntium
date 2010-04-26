require 'test_helper'
require 'mocha'

class ApplicationTest < ActiveSupport::TestCase

  include Mocha::API
  
  def setup
    @account = Account.create!({:name => 'foo', :password => 'pass'})
  end

  test "check modified" do
    application = Application.create!(:account_id => @account.id, :name => 'application1', :interface => 'rss', :password => 'foo')
    
    chan1 = new_channel application.account, 'Uno'
    chan2 = new_channel application.account, 'Dos'
    chan2.priority = chan1.priority - 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    application.route(msg, 'test')
    
    assert_equal chan2.id, msg.channel_id
    
    sleep 2
    
    chan2.priority = chan1.priority + 10
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://1239', :subject => 'foo', :body => 'bar')
    application.route(msg, 'test')
    
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
    
    application.accept msg, nil
  end
  
end
