require 'test_helper'

class MultimodemIsmsChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @chan = Channel.make :multimodem_isms
  end

  [:host, :user, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "should not save if port is not a number" do
    @chan.configuration[:port] = 'foo'
    assert_false @chan.save
  end

  test "should not save if port is negative" do
    @chan.configuration[:port] = -430
    assert_false @chan.save
  end

  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendMultimodemIsmsMessageJob
  end

  test "on enable binds queue" do
    chan = Channel.make_unsaved :multimodem_isms
    Queues.expects(:bind_ao).with chan
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

  test "on pause disables worker queue" do
    @chan.paused = true
    @chan.save!

    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_false wqs[0].enabled
  end

  test "on unpause enables worker queue" do
    @chan.paused = true
    @chan.save!

    @chan.paused = false
    @chan.save!

    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_true wqs[0].enabled
  end
end
