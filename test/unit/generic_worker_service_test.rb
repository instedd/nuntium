require 'test_helper'
require 'mocha'

class GenericWorkerServiceTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @service = GenericWorkerService.new
    
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :direction => Channel::Outgoing)
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }
    @chan.save!
    
    StubJob.value_after_perform = nil
  end

  test "should subscribe to enabled channels" do
    Queues.expects(:subscribe_ao).with(@chan, kind_of(MQ))
    
    @service.start
  end
  
  test "should subscribe to notifications" do
    Queues.expects(:subscribe_notifications).with(kind_of(MQ))
    
    @service.start
  end
  
  test "should execute job when enqueued" do
    @service.start
    
    msg = AOMessage.create!(:application => @app, :channel => @chan)
    
    Queues.publish_ao msg, StubJob.new
    sleep 0.3
    
    assert_equal 10, StubJob.value_after_perform
  end
end

class StubJob

  class << self
    attr_accessor :value_after_perform
  end
  
  def perform
    StubJob.value_after_perform = 10
  end

end
