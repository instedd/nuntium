require 'test_helper'

class UnsubscribeFromQueueJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "perform" do
    worker = mock('worker');
    worker.expects(:unsubscribe_from_queue).with('foo')

    job = UnsubscribeFromQueueJob.new('foo')
    job.perform worker
  end
end
