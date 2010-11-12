module GenericChannelHandlerTest
  def test_should_enqueue
    assert_handler_should_enqueue_ao_job @chan
  end

  def test_on_create_binds_queue
    chan = Channel.make_unsaved :clickatell
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end

  def test_on_create_creates_worker_queue
    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_equal 1, wqs.length
    assert_equal 'fast', wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end

  def test_on_enable_enables_worker_queue
    @chan.enabled = false
    @chan.save!

    @chan.enabled = true
    @chan.save!

    assert_true WorkerQueue.first(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)]).enabled
  end

  def test_on_resume_enables_worker_queue
    @chan.paused = true
    @chan.save!

    @chan.paused = false
    @chan.save!

    assert_true WorkerQueue.first(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)]).enabled
  end

  def test_on_pause_disables_worker_queue
    @chan.paused = true
    @chan.save!

    assert_false WorkerQueue.first(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)]).enabled
  end

  def eest_on_destroy_destroys_worker_queue
    @chan.destroy

    assert_equal 0, WorkerQueue.count(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
  end
end
