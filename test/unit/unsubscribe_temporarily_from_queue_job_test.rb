require 'test_helper'

class UnsubscribeTemporarilyFromQueueJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "perform" do
    worker = mock('worker');
    worker.expects(:unsubscribe_temporarily_from_queue).with('foo')

    job = UnsubscribeTemporarilyFromQueueJob.new('foo')
    job.perform worker
  end
end
