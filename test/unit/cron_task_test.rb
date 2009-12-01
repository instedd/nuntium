require 'test_helper'

class CronTaskTest < ActiveSupport::TestCase
  
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
  
end
