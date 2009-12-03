require "test_helper"
require "lib/services/cron_daemon"

class CronDaemonTest < ActiveSupport::TestCase
  
  include CronDaemonRun
  
  test "enqueue tasks to run" do
    t1 = CronTask.create :interval => 30, :next_run => base_time + 10
    t2 = CronTask.create :interval => 35, :next_run => base_time + 20
    t3 = CronTask.create :interval => 40, :next_run => base_time + 30
    t4 = CronTask.create :interval => 45, :next_run => base_time + 40
    t5 = CronTask.create :interval => 60, :next_run => base_time + 50
    
    set_current_time(base_time + 30) 
    
    Delayed::Job.expects(:enqueue).with(responds_with(:task_id, t1.id))
    Delayed::Job.expects(:enqueue).with(responds_with(:task_id, t2.id))
    Delayed::Job.expects(:enqueue).with(responds_with(:task_id, t3.id))

    cron_run

    tasks = [t1,t2,t3,t4,t5]
    tasks.each { |t| t.reload }

    assert_equal base_time + 60, t1.next_run
    assert_equal base_time + 65, t2.next_run
    assert_equal base_time + 70, t3.next_run
    assert_equal base_time + 40, t4.next_run
    assert_equal base_time + 50, t5.next_run
    
  end
  
end