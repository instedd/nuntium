require 'test_helper'

class ChannelSubscriptionJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "perform" do
    worker = mock('worker');
    worker.expects(:subscribe_to_channel).with(1)
  
    job = ChannelSubscriptionJob.new(1)
    job.perform worker
  end
end
