require 'test_helper'

class WorkerQueueTest < ActiveSupport::TestCase

  test "publish notification after create" do
    tasks = []
  
    Queues.subscribe_notifications '1', 'wk' do |header, task|
      tasks << task
    end
  
    wk = WorkerQueue.create!(:queue_name => 'queue_1', :working_group => 'wk', :ack => true)
    sleep 0.5
    
    assert_equal 1, tasks.length
    assert_kind_of SubscribeToQueueJob, tasks[0]
    assert_equal 'queue_1', tasks[0].queue_name
  end
  
  test "publish notification after destroy" do
    wk = WorkerQueue.create!(:queue_name => 'queue_2', :working_group => 'wk', :ack => true)
    sleep 0.5
  
    tasks = []
  
    Queues.subscribe_notifications '2', 'wk' do |header, task|
      tasks << task
    end
  
    wk.destroy
    sleep 0.5
    
    assert_equal 1, tasks.length
    assert_kind_of UnsubscribeFromQueueJob, tasks[0]
    assert_equal 'queue_2', tasks[0].queue_name
  end

end
