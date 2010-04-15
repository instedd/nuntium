require 'test_helper'

class SubscribeToQueueJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "perform" do
    worker = mock('worker');
    worker.expects(:subscribe_to_queue).with('foo')
  
    job = SubscribeToQueueJob.new('foo')
    job.perform worker
  end
end
