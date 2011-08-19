require 'test_helper'

class ScheduledJobsServiceTest < ActiveSupport::TestCase
  cattr_accessor :flag

  def setup
    @@flag = 0
    @service = ScheduledJobsService.new
  end

  test "executes the only one" do
    job = ScheduledJob.create! :job => SetFlag.new(1), :run_at => Time.now

    @service.execute_once

    assert_equal 1, self.class.flag
    assert_equal 0, ScheduledJob.count
  end

  test "executes none" do
    ScheduledJob.create! :job => SetFlag.new(1), :run_at => 1.minute.from_now

    @service.execute_once

    assert_equal 0, self.class.flag
    assert_equal 1, ScheduledJob.count
  end

  test "resilient to fails" do
    ScheduledJob.create! :job => Fail.new, :run_at => Time.now

    @service.execute_once

    assert_equal 1, ScheduledJob.count
  end

  class SetFlag
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def perform
      ScheduledJobsServiceTest.flag = @value
    end
  end

  class Fail
     def perform
       raise "Oops"
     end
  end

end

