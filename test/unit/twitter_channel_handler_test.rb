require 'test_helper'

class TwitterChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'twitter', :protocol => 'sms')
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendTwitterMessageJob
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
