require 'test_helper'

class DelayedJobTest < ActiveSupport::TestCase

  test "enqueue with channel id" do
    Delayed::Job.enqueue_with_channel_id 1, SendSmppMessageJob.new(1, 2, 3)
    
    jobs = Delayed::Job.all
    assert_equal 1, jobs.length
    assert_equal 1, jobs[0].channel_id
    assert_true jobs[0].handler.include?('SendSmppMessageJob')
  end

end
