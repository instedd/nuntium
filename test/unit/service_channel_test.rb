module ServiceChannelTest
  def test_should_enqueue_when_handling
    assert_channel_should_enqueue_ao_job @chan
  end

  def test_on_create_publishes_start_channel
    chan = @chan.class.make_unsaved

    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StartChannelJob && job.id == chan.id && kind == chan.class.kind
    end

    chan.save!
  end

  def test_on_create_binds_queue
    chan = @chan.class.make_unsaved
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end

  def test_on_destroy_publishes_stop_channel
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StopChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.destroy
  end

  def test_on_change_publishes_restart_channel
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == RestartChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.priority = 1234
    @chan.save!
  end

  def test_on_enable_publishes_start_channel
    @chan.enabled = false
    @chan.save!

    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StartChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.enabled = true
    @chan.save!
  end

  def test_on_disable_publishes_stop_channel
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StopChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.enabled = false
    @chan.save!
  end

  def test_on_pause_publishes_stop_channel
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StopChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.paused = true
    @chan.save!
  end

  def test_on_resume_publishes_start_channel
    @chan.paused = true
    @chan.save!

    Queues.expects(:publish_notification).with do |job, kind|
      job.class == StartChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.paused = false
    @chan.save!
  end

  def test_on_account_change_touches
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == RestartChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    @chan.account.save!
  end

  def test_on_application_change_touches
    Queues.expects(:publish_notification).with do |job, kind|
      job.class == RestartChannelJob && job.id == @chan.id && kind == @chan.class.kind
    end

    Application.make :account => @chan.account
  end
end
