module GenericChannelTest
  def test_should_enqueue
    assert_handler_should_enqueue_ao_job @chan
  end

  def test_on_create_binds_queue
    chan = @chan.class.make_unsaved
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end

  def test_on_create_creates_worker_queue
    wq = WorkerQueue.for_channel @chan
    assert_equal 'fast', wq.working_group
    assert_true wq.ack
    assert_true wq.enabled
  end

  def test_on_enable_enables_worker_queue
    @chan.enabled = false
    @chan.save!

    @chan.enabled = true
    @chan.save!

    assert_true WorkerQueue.for_channel(@chan).enabled
  end

  def test_on_resume_enables_worker_queue
    @chan.paused = true
    @chan.save!

    @chan.paused = false
    @chan.save!

    assert_true WorkerQueue.for_channel(@chan).enabled
  end

  def test_on_pause_disables_worker_queue
    @chan.paused = true
    @chan.save!

    assert_false WorkerQueue.for_channel(@chan).enabled
  end

  def test_on_destroy_destroys_worker_queue
    @chan.destroy

    assert_nil WorkerQueue.for_channel(@chan)
  end
end
