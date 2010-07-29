require 'test_helper'

class DtacChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @chan = Channel.make :dtac
  end
  
  [:user, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendDtacMessageJob
  end
  
  test "on enable binds queue" do
    chan = Channel.make_unsaved :dtac
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end
  
  test "on enable creates worker queue" do
    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_equal 1, wqs.length
    assert_equal 'fast', wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "on disable destroys worker queue" do
    @chan.update_attribute :enabled, false
    assert_equal 0, WorkerQueue.count(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
  end
end
