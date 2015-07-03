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

require 'test_helper'

class GenericWorkerServiceTest < ActiveSupport::TestCase

  @@id = 10000000
  @@working_group = 'fast'

  def setup
    Thread.new { EM.run }
    sleep 0.1 until EM.reactor_running?

    @@id = @@id + 1
    @account = Account.make
    @service = GenericWorkerService.new(@@id, @@working_group)

    @chan = ClickatellChannel.make :account => @account

    super
  end

  def teardown
    @service.stop false # do not stop event machine

    EM.stop
    sleep 0.1 while EM.reactor_running?
  end

  test "should subscribe to enabled channels" do
    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel))

    @service.start
  end

  test "should not subscribe if another working group" do
    Queues.expects(:subscribe).times(0)

    @service = GenericWorkerService.new(@@id, 'other')
    @service.start
  end

  test "should subscribe to notifications" do
    Queues.expects(:subscribe_notifications).with(@@id, @@working_group, kind_of(Bunny::Channel))

    @service.start
  end

  test "should execute job when enqueued" do
    header = mock('header')
    header.expects(:ack)

    job = mock('job')
    job.expects(:perform).returns(true)

    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel)).yields(header, job)
    @service.start

    # Give EM the opportunity to run queued jobs (header.ack)
    Thread.pass
  end

  test "should execute job notification when enqueued" do
    header = mock('header')
    job = mock('job')
    job.expects(:perform).with(@service)
    Queues.expects(:subscribe)
    Queues.expects(:subscribe_notifications).with(@@id, @@working_group, kind_of(Bunny::Channel)).yields(header, job)
    @service.start
    sleep 0.2

    Thread.pass
  end

  test "should reschedule on unknown exception" do
    header = mock('header')
    header.expects(:ack)

    job = mock('job')
    job.expects(:perform).raises(RuntimeError.new)
    job.expects(:reschedule)

    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel)).yields(header, job)

    @service.start
  end

  test "should reschedule on timeout error" do
    header = mock('header')
    header.expects(:ack)

    job = mock('job')
    job.expects(:perform).raises(Timeout::Error.new)
    job.expects(:reschedule)

    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel)).yields(header, job)

    @service.start
  end

  test "should unsubscribe temporarily on exception on reschedule" do
    header = mock('header')

    job = mock('job')
    job.expects(:perform).raises(RuntimeError.new)
    job.expects(:reschedule).raises(RuntimeError.new)

    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel)).yields(header, job)

    jobs = []
    Queues.expects(:publish_notification).with do |job, working_group, mq|
      working_group == @@working_group &&
        job.queue_name == Queues.ao_queue_name_for(@chan) &&
        job.kind_of?(UnsubscribeTemporarilyFromQueueJob)
    end

    @service.start
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

    Queues.expects(:subscribe).with(Queues.ao_queue_name_for(@chan), true, true, kind_of(Bunny::Channel))

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

  test "should unsubscribe temporarily when told so" do
    @service.start

    queue_name = Queues.ao_queue_name_for(@chan)

    seq = sequence('seq')
    @service.expects(:start_ignoring).with(queue_name).in_sequence(seq)
    @service.expects(:stop_ignoring_later).with(queue_name).in_sequence(seq)

    @service.unsubscribe_temporarily_from_queue Queues.ao_queue_name_for(@chan)
  end

  test "should ignore subscribe when temporarily unsubscribed" do
    @service.start

    queue_name = Queues.ao_queue_name_for(@chan)

    @service.start_ignoring queue_name

    Queues.expects(:subscribe).never

    @service.subscribe_to_queue queue_name
  end

  test "should ignore unsubscribe when temporarily unsubscribed" do
    @service.start

    queue_name = Queues.ao_queue_name_for(@chan)

    @service.start_ignoring queue_name

    @service.sessions.expects(:delete).never

    @service.unsubscribe_from_queue queue_name
  end

  test "should ignore unsubscribe_temporarily when temporarily unsubscribed" do
    @service.start

    queue_name = Queues.ao_queue_name_for(@chan)

    @service.start_ignoring queue_name

    @service.expects(:start_ignoring).never

    @service.unsubscribe_temporarily_from_queue queue_name
  end

  test "should not ignore subscribe after temporarily unsubscribed" do
    @service.start

    queue_name = Queues.ao_queue_name_for(@chan)

    @service.start_ignoring queue_name

    Queues.expects(:subscribe).times(1)
    @service.stop_ignoring queue_name
  end

end
