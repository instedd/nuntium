require 'test_helper'

class WorkerQueueTest < ActiveSupport::TestCase

  include Mocha::API
  
  def setup
    WorkerQueue.publish_notification_delay = 0.5
  end
  
  test "change publish notification delay" do
    WorkerQueue.publish_notification_delay = 10
    assert_equal 10, WorkerQueue.publish_notification_delay
  end

  test "publish notification after create" do
    Queues.expects(:publish_notification).with do |task, working_group|
      task.kind_of? SubscribeToQueueJob and
        task.queue_name == 'queue_1' and
        working_group == 'wk'
    end
  
    WorkerQueue.create! :queue_name => 'queue_1', :working_group => 'wk', :ack => true
    
    sleep 1
  end
  
  test "publish notification after create check delay" do
    WorkerQueue.publish_notification_delay = 0.5
    # This will never be invoked since the delay is there
    Queues.expects(:publish_notification).times(0)
    WorkerQueue.create! :queue_name => 'queue_1', :working_group => 'wk', :ack => true
  end
  
  test "publish notification after destroy" do
    wk = WorkerQueue.create! :queue_name => 'queue_2', :working_group => 'wk', :ack => true
    
    Queues.expects(:publish_notification).with do |task, working_group|
      task.kind_of? UnsubscribeFromQueueJob and
        task.queue_name == 'queue_2' and
        working_group == 'wk'
    end
    
    wk.destroy
  end

end
