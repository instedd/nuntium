require 'test_helper'
require 'mocha'


class CronTaskTest < ActiveSupport::TestCase

  self.use_transactional_fixtures = false

  include Mocha::API
  
  teardown :clean_database
  
  test "should save empty task" do
    task = CronTask.new :interval => 0
    assert task.save!
    t2 = CronTask.find_by_id task.id
    assert_equal 0, t2.interval
  end
  
  test "should create task when creating qst account and drop if changed" do
    account = Account.create :name => 'account', :password => 'foo', :interface => 'qst_client'
    
    assert_equal 2, account.cron_tasks.size
    t1, t2 = account.cron_tasks.all
    
    assert_equal PushQstMessageJob, t1.get_handler.class
    assert_equal account.id, t1.parent_id
    
    assert_equal PullQstMessageJob, t2.get_handler.class
    assert_equal account.id, t2.parent_id
    
    account.update_attribute(:interface, 'rss')
    assert_equal 0, account.cron_tasks.size
    assert_equal 0, CronTask.all.size
  end
  
  test "should create task when changing account to qst" do
    account = Account.create :name => 'account', :password => 'foo', :interface => 'rss'
    assert_equal 0, account.cron_tasks.size
    assert_equal 0, CronTask.all.size
    
    account.update_attribute(:interface, 'qst_client')
    account.reload
    assert_equal 2, account.cron_tasks.size
    
    t1, t2 = account.cron_tasks.all
    
    assert_equal PushQstMessageJob, t1.get_handler.class
    assert_equal account.id, t1.parent_id
    
    assert_equal PullQstMessageJob, t2.get_handler.class
    assert_equal account.id, t2.parent_id
  end
  
  test "should drop task with account" do
    account = Account.create :name => 'account', :password => 'foo', :interface => 'qst_client'
    
    assert_equal 2, account.cron_tasks.size
    assert_equal PushQstMessageJob, account.cron_tasks.first.get_handler.class
    assert_equal PullQstMessageJob, account.cron_tasks.last.get_handler.class
    
    account.destroy
    assert_equal 0, CronTask.all.size
  end
  
  test "should create twitter task for channel" do
    ch = create_channel('twitter')
    assert_equal 1, CronTask.all.size
    assert_equal ch.id, CronTask.first.get_handler.channel_id
    assert_equal ReceiveTwitterMessageJob, CronTask.first.get_handler.class
  end
  
  test "should create pop3 task for channel" do
    ch = create_channel('pop3')
    assert_equal 1, CronTask.all.size
    assert_equal ch.id, CronTask.first.get_handler.channel_id
    assert_equal ReceivePop3MessageJob, CronTask.first.get_handler.class
  end
  
  test "should not create task for non task channel" do
    create_channel 'qst_server'
    assert_equal 0, CronTask.all.size
  end
  
  test "should not save with negative interval" do
    task = CronTask.new :interval => -20
    assert !task.save
  end
  
  test "should save account task" do
    account = Account.create :name => 'account', :password => 'foo'
    task = CronTask.new :parent => account, :interval => 10
    assert task.save!
    
    t2 = CronTask.find_by_id task.id
    assert_equal 10, t2.interval
    assert_equal account, t2.parent
  end
  
  test "should save channel task" do
    ch = create_channel
    
    task = CronTask.new :parent => ch, :interval => 50
    assert task.save!
    
    t2 = CronTask.find_by_id task.id
    assert_equal 50, t2.interval
    assert_equal ch.name, t2.parent.name
  end
  
  test "should execute task first time" do
    set_current_time
    expect_execution
    task = create_task
    
    assert_equal :handler_success, task.perform
    assert_equal base_time, task.last_run 
  end
  
  test "should execute task after interval time" do
    set_current_time base_time + 60
    task = create_task base_time
    expect_execution
    
    assert_equal :handler_success, task.perform
    assert_equal base_time + 60, task.last_run 
  end

  test "should execute task after interval time minus tolerance" do
    set_current_time base_time + 55
    task = create_task base_time
    expect_execution
    
    assert_equal :handler_success, task.perform
    assert_equal base_time + 55, task.last_run 
  end

  test "should execute task after more than interval time" do
    set_current_time base_time + 95
    task = create_task base_time
    expect_execution
    
    assert_equal :handler_success, task.perform
    assert_equal base_time + 95, task.last_run 
  end
  
  test "should not execute task within interval time" do
    set_current_time base_time + 45
    task = create_task base_time
    expect_execution 0
    
    assert_equal :dropped, task.perform
    assert_equal base_time, task.last_run 
  end
  
  test "should not execute second task when first one is still executing" do
    expect_execution 1
  
    set_current_time base_time + 1
    task = create_task base_time, create_handler, 1, 2
    th = Thread.start do
      assert_equal :handler_success, task.perform
    end
    sleep 1
    task2 = CronTask.find_by_id(task.id)
    assert_equal :dropped, task2.perform
    task2.reload
    assert_not_nil task2.locked_tag
    th.join
  end
  
  def create_channel(kind = 'qst_server')
    account = Account.create :name => 'account', :password => 'foo'
    ch = Channel.new :name =>'channel', :account_id => account.id, :kind => kind, :protocol => 'sms'
    ch.configuration = {:password => 'foo', :password_confirmation => 'foo', :user => 'foobar', :port => 600, :host => 'example.com'}
    ch.save!
    ch
  end

  def create_task(last_run=nil, handler=create_handler, interval = 60, sleep_time = 0)
    task = CronTask.new :interval => interval, :last_run => last_run
    handler.sleep_time = sleep_time if sleep_time > 0 
    task.set_handler(handler)
    assert task.save!
    task
  end
  
  def create_handler(quota=nil, arg=:arg)
    h = Handler.new arg
    h.expects(:quota=).with(quota) unless quota.nil?
    return h
  end
  
  def expect_execution(times=1, arg=:arg)
    Witness.expects(:execute).with(arg).times(times)
  end
  
  def clean_database
    [Account, AccountLog, Channel, CronTask, WorkerQueue].each(&:delete_all)
  end
  
  class Handler
    attr_accessor :sleep_time
    def initialize(arg)
      @arg = arg
    end
    def perform
      sleep sleep_time if !sleep_time.nil? && sleep_time > 0
      Witness.execute @arg
      return :handler_success
    end
  end
  
  class Witness
  end
  
end
