# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

module GenericChannelTest
  def test_should_enqueue
    assert_channel_should_enqueue_ao_job @chan
  end

  def test_on_create_binds_queue
    if respond_to?(:new_unsaved_channel)
      chan = new_unsaved_channel
    else
      chan = @chan.class.make_unsaved
    end
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
