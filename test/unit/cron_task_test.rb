require 'test_helper'
require 'mocha'


class CronTaskTest < ActiveSupport::TestCase

  include Mocha::API
  
  test "should save empty task" do
    task = CronTask.new :interval => 0
    assert task.save!
    t2 = CronTask.find_by_id task.id
    assert_equal 0, t2.interval
  end
  
  test "should not save with negative interval" do
    task = CronTask.new :interval => -20
    assert !task.save
  end
  
  test "should save application task" do
    app = Application.create :name => 'app', :password => 'foo'
    task = CronTask.new :parent => app, :interval => 10
    assert task.save!
    
    t2 = CronTask.find_by_id task.id
    assert_equal 10, t2.interval
    assert_equal app, t2.parent
  end
  
  test "should save channel task" do
    app = Application.create :name => 'app', :password => 'foo'
    ch = Channel.new :name =>'channel', :application_id => app.id, :kind => 'qst', :protocol => 'sms'
    ch.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    ch.save!
    
    assert !app.nil?
    assert !ch.nil?
    
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
  

  def create_task(last_run=nil, handler=create_handler)
    task = CronTask.new :interval => 60, :last_run => last_run
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
  
  class Handler
    def initialize(arg)
      @arg = arg
    end
    def perform
      Witness.execute @arg
      return :handler_success
    end
  end
  
  class Witness
  end
  
end
