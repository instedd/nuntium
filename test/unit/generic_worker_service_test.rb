require 'test_helper'

class GenericWorkerServiceTest < ActiveSupport::TestCase
  
  @@id = 10000000
  @@working_group = 'fast'
  @@suspension_time = 0
  
  def setup
    @@id = @@id + 1
    @account = Account.make
    @service = GenericWorkerService.new(@@id, @@working_group, @@suspension_time)
    
    @chan = Channel.make :clickatell, :account => @account
    
    super
  end

	def teardown
	  @service.stop false # do not stop event machine
	end

  test "should subscribe to enabled channels" do
    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, kind_of(MQ))
    
    @service.start
  end
  
  test "should not subscribe if another working group" do
    Queues.expects(:subscribe).times(0)
  
    @service = GenericWorkerService.new(@@id, 'other')
    @service.start
  end
  
  test "should subscribe to notifications" do
    Queues.expects(:subscribe_notifications).with(@@id, @@working_group, kind_of(MQ))
    
    @service.start
  end
  
  test "should execute job when enqueued" do
    header = mock('header')
    header.expects(:ack)
    
    job = mock('job')
    job.expects(:perform).returns(true)
    
    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, kind_of(MQ)).yields(header, job)
    @service.start
  end
  
  test "should execute job notification when enqueued" do
    header = mock('header')
    job = mock('job')
    job.expects(:perform).with(@service)
    Queues.expects(:subscribe_notifications).with(@@id, @@working_group, kind_of(MQ)).yields(header, job)
    @service.start
  end
  
  test "should unsubscribe channel temporarily on unknown exception" do
    header = mock('header')
    
    job = mock('job')
    job.expects(:perform).raises(Exception.new)
    
    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, kind_of(MQ)).yields(header, job)
    
    jobs = []
    Queues.expects(:publish_notification).times(2).with do |job, working_group, mq|
      jobs << job
      working_group == @@working_group and job.queue_name == Queues.ao_queue_name_for(@chan)
    end
    
    @service.start
    
    assert_equal 2, jobs.size
    assert_kind_of UnsubscribeFromQueueJob, jobs[0]
    assert_kind_of SubscribeToQueueJob, jobs[1]
  end
  
  test "should unsubscribe when told so" do
    @service.start
    
    queue_name = Queues.ao_queue_name_for(@chan)
    
    mq = mock('mq')
    mq.expects(:close).at_least_once
    
    @service.sessions.expects(:delete).at_least_once.with(queue_name).returns(mq)
    
    @service.unsubscribe_from_queue queue_name
  end
  
  test "should subscribe when told so" do
    @service.start
    @service.unsubscribe_from_queue Queues.ao_queue_name_for(@chan)
    
    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, kind_of(MQ))
    
    @service.subscribe_to_queue Queues.ao_queue_name_for(@chan)
  end
  
  test "should not subscribe when told so if channel is disabled" do
    @service.start
    @service.unsubscribe_from_queue Queues.ao_queue_name_for(@chan)
    
    @chan.enabled = false
    @chan.save!
    
    Queues.expects(:subscribe).times(0)
    
    @service.subscribe_to_queue Queues.ao_queue_name_for(@chan)
  end
  
end
