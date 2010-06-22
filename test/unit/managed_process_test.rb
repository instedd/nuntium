require 'test_helper'

class ManagedProcessTest < ActiveSupport::TestCase
  
  test "publish start notification on create" do
    jobs = collect_jobs
    mp = ManagedProcess.make
    assert_job jobs, StartProcessJob, mp
  end
  
  test "publish stop notification on destroy" do
    mp = ManagedProcess.make
    jobs = collect_jobs
    mp.destroy
    assert_job jobs, StopProcessJob, mp
  end
  
  test "publish restart notification on update" do
    mp = ManagedProcess.make
    jobs = collect_jobs
    mp.touch
    assert_job jobs, RestartProcessJob, mp
  end
  
  def collect_jobs
    jobs = []
    Queues.expects(:publish_notification).with do |job, routing_key, mq|
       jobs << job
       routing_key == 'managed_processes'
    end
    jobs
  end
  
  def assert_job(jobs, kind, mp)
    assert_equal 1, jobs.length
    assert_kind_of kind, jobs[0]
    assert_equal mp.id, jobs[0].id
  end
  
end
