require 'test_helper'
require 'mocha'

class ManagedProcessTest < ActiveSupport::TestCase
  include Mocha::API

  test "publish start notification on create" do
    jobs = []
  
    Queues.expects(:publish_notification).with do |job, routing_key, mq|
       jobs << job
       routing_key == 'managed_processes'
    end
  
    mp = ManagedProcess.create!(
      :application_id => 1,
      :name => 'name',
      :start_command => 'start',
      :stop_command => 'stop',
      :pid_file => 'pid',
      :log_file => 'log'
    )
    
    assert_equal 1, jobs.length
    assert_kind_of StartProcessJob, jobs[0]
    assert_equal mp.id, jobs[0].id
  end
  
  test "publish stop notification on destroy" do
    mp = ManagedProcess.create!(
      :application_id => 1,
      :name => 'name',
      :start_command => 'start',
      :stop_command => 'stop',
      :pid_file => 'pid',
      :log_file => 'log'
    )
    
    jobs = []
  
    Queues.expects(:publish_notification).with do |job, routing_key, mq|
       jobs << job
       routing_key == 'managed_processes'
    end
    
    mp.destroy
    
    assert_equal 1, jobs.length
    assert_kind_of StopProcessJob, jobs[0]
    assert_equal mp.id, jobs[0].id
  end
  
  test "publish restart notification on update" do
    mp = ManagedProcess.create!(
      :application_id => 1,
      :name => 'name',
      :start_command => 'start',
      :stop_command => 'stop',
      :pid_file => 'pid',
      :log_file => 'log'
    )
    
    jobs = []
  
    Queues.expects(:publish_notification).with do |job, routing_key, mq|
       jobs << job
       routing_key == 'managed_processes'
    end
    
    mp.touch
    
    assert_equal 1, jobs.length
    assert_kind_of RestartProcessJob, jobs[0]
    assert_equal mp.id, jobs[0].id
  end
end
