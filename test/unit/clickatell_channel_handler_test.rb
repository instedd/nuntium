require 'test_helper'

class ClickatellChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms')
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }
  end
  
  [:user, :password, :from, :api_id, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should save" do
    assert @chan.save
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendClickatellMessageJob
  end
  
  test "on enable binds queue" do
    Queues.expects(:bind_ao).with(@chan)
    @chan.save!
  end
  
  test "on enable creates worker queue" do
    @chan.save!
    
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal Queues.ao_queue_name_for(@chan), wqs[0].queue_name
    assert_equal 'channels', wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "on disable destroys worker queue" do
    @chan.save!
    
    @chan.enabled = false
    @chan.save!
    
    assert_equal 0, WorkerQueue.count
  end
end
