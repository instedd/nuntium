require 'test_helper'

class ManagedProcessTest < ActiveSupport::TestCase
  test "initial status" do
    p1 = ManagedProcess.create!(:name => 'one')
    p2 = ManagedProcess.create!(:name => 'two')
    status = ManagedProcess.status
    assert_equal({p1 => :start, p2 => :start}, status)
  end
  
  test "new status" do
    p1 = ManagedProcess.create!(:name => 'nothing')
    p2 = ManagedProcess.create!(:name => 'stop')
    p3 = ManagedProcess.create!(:name => 'restart')
    p4 = ManagedProcess.create!(:name => 'disabled', :enabled => true)
    p5 = ManagedProcess.create!(:name => 'enabled', :enabled => false)
    previous_status = ManagedProcess.status
    
    sleep 1
    
    p2.delete
    p3.name = 'restarted'; p3.save!
    p4.enabled = false; p4.save!
    p5.enabled = true; p5.save!
    p6 = ManagedProcess.create!(:name => 'start')
    
    status = ManagedProcess.status(previous_status)    
    assert_equal({p2 => :stop, p3 => :restart, p4 => :stop, p5 => :start, p6 => :start}, status)
  end
end
