require 'test_helper'

class SmppChannelHandlerTest < ActiveSupport::TestCase
  
  setup :initialize_objects

  def initialize_objects
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'smpp', :protocol => 'smpp')
    @chan.configuration = {:host => 'host', :port => '3200', :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :system_type => 'smpp', :mt_encodings => ['ascii'] }
  end
  
  def assert_validates_presence_of(field)
    @chan.configuration.delete field
    assert !@chan.save
  end
  
  [:host, :port, :source_ton, :source_npi, :destination_ton, :destination_npi, :user, :password, :system_type].each do |field|
    test "should validate_presence_of #{field}" do
      assert_validates_presence_of field
    end
  end
  
  test "should save" do
    assert @chan.save
  end
  
  test "sould create delayed job if channel throttle is nil" do
    msg = AOMessage.new(:application_id => @app.id)
    @chan.handler.handle(msg)
    
    jobs = Delayed::Job.all
    assert_equal 1, jobs.length
    assert_equal 0, ThrottledJob.all.length
    
    assert_equal SendSmppMessageJob, jobs[0].payload_object.class
  end
  
  test "sould create throttled job if channel throttle is not nil" do
    @chan.throttle = 20
    msg = AOMessage.new(:application_id => @app.id)
    @chan.handler.handle(msg)
    
    jobs = ThrottledJob.all
    assert_equal 0, Delayed::Job.all.length
    assert_equal 1, jobs.length
    
    assert_equal @chan.id, jobs[0].channel_id
    assert_equal SendSmppMessageJob, jobs[0].payload_object.class
  end
  
  test "on enable creates managed process" do
    @chan.save!
    
    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_equal @chan.application.id, proc.application_id
    assert_equal "SMPP #{@chan.name}", proc.name
    assert_equal "drb_smpp_daemon_ctl.rb start -- test #{@chan.id}", proc.start_command
    assert_equal "drb_smpp_daemon_ctl.rb stop -- test #{@chan.id}", proc.stop_command
    assert_equal "drb_smpp_daemon.#{@chan.id}.pid", proc.pid_file
    assert_equal "drb_smpp_daemon_#{@chan.id}.log", proc.log_file
  end
  
  test "on destroy deletes managed process" do
    @chan.save!
    @chan.destroy
    
    assert_equal 0, ManagedProcess.count
  end
  
  test "on change touches managed process" do
    @chan.save!
    
    proc = ManagedProcess.first
    
    sleep 1
    @chan.touch
    
    assert ManagedProcess.first.updated_at > proc.updated_at
  end
  
end
