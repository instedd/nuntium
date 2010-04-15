require 'test_helper'
require 'mocha'

class CronWorkerServiceTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @app = Application.create!(:name => 'app', :password => 'foo')
    @service = CronWorkerService.new
    
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :direction => Channel::Outgoing)
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }
    @chan.save!
    
    StubCronJob.value_after_perform = nil
  end
  
  def teardown
	  @service.stop false # do not stop event machine
	end
  
  test "should subscribe to cron tasks" do
    Queues.expects(:subscribe_cron_tasks).with(kind_of(MQ))
    
    @service.start
  end
  
  test "should execute cron task" do
    @service.start
    
    Queues.publish_cron_task StubCronJob.new
    sleep 0.5
    
    assert_equal 10, StubCronJob.value_after_perform
  end
end

class StubCronJob
  
  class << self
    attr_accessor :value_after_perform
  end
  
  def perform
    StubCronJob.value_after_perform = 10
  end
  
end
