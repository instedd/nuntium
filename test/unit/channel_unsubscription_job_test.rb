require 'test_helper'

class ChannelUnsubscriptionJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "perform" do
    worker = mock('worker');
    worker.expects(:unsubscribe_from_channel).with(1)
  
    job = ChannelUnsubscriptionJob.new(1)
    job.perform worker
  end
end
