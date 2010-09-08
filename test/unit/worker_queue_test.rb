require 'test_helper'

class WorkerQueueTest < ActiveSupport::TestCase

  include Mocha::API

  test "publish notification after create" do
    Queues.expects(:publish_notification).with do |task, working_group|
      task.kind_of? SubscribeToQueueJob and
        task.queue_name == 'queue_1' and
        working_group == 'wk'
    end
  
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
