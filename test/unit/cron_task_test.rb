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

class CronTaskTest < ActiveSupport::TestCase

  self.use_transactional_fixtures = false

  setup :clean_database

  test "should save empty task" do
    task = CronTask.new :interval => 0
    assert task.save!
    t2 = CronTask.find_by_id task.id
    assert_equal 0, t2.interval
  end

  test "should create task when creating qst account and drop if changed" do
    application = Application.make! :qst_client

    assert_equal 2, application.cron_tasks.size
    t1, t2 = application.cron_tasks.all

    assert_equal PushQstMessageJob, t1.get_handler.class
    assert_equal application.id, t1.parent_id

    assert_equal PullQstMessageJob, t2.get_handler.class
    assert_equal application.id, t2.parent_id

    application.update_attribute(:interface, 'rss')
    assert_equal 0, application.cron_tasks.size
    assert_equal 0, CronTask.all.size
  end

  test "should create task when changing account to qst" do
    application = Application.make! :rss

    assert_equal 0, application.cron_tasks.size
    assert_equal 0, CronTask.all.size

    application.update_attribute :interface, 'qst_client'
    application.reload
    assert_equal 2, application.cron_tasks.size

    t1, t2 = application.cron_tasks.all

    assert_equal PushQstMessageJob, t1.get_handler.class
    assert_equal application.id, t1.parent_id

    assert_equal PullQstMessageJob, t2.get_handler.class
    assert_equal application.id, t2.parent_id
  end

  test "should drop task with account" do
    application = Application.make! :qst_client
    application.destroy
    assert_equal 0, CronTask.all.size
  end

  test "should create twitter task for channel" do
    ch = TwitterChannel.make!
    assert_equal 1, CronTask.all.size
    assert_equal ch.id, CronTask.first.get_handler.channel_id
    assert_equal ReceiveTwitterMessageJob, CronTask.first.get_handler.class
  end

  test "should create pop3 task for channel" do
    ch = Pop3Channel.make!
    assert_equal 1, CronTask.all.size
    assert_equal ch.id, CronTask.first.get_handler.channel_id
    assert_equal ReceivePop3MessageJob, CronTask.first.get_handler.class
  end

  test "should not create task for non task channel" do
    ch = QstServerChannel.make!
    assert_equal 0, CronTask.all.size
  end

  test "should not save with negative interval" do
    task = CronTask.new :interval => -20
    assert !task.save
  end

  test "should save account task" do
    account = Account.make!
    task = CronTask.new :parent => account, :interval => 10
    assert task.save!

    t2 = CronTask.find_by_id task.id
    assert_equal 10, t2.interval
    assert_equal account, t2.parent
  end

  test "should save channel task" do
    ch = QstServerChannel.make!

    task = CronTask.new :parent => ch, :interval => 50
    assert task.save!

    t2 = CronTask.find_by_id task.id
    assert_equal 50, t2.interval
    assert_equal ch.name, t2.parent.name
  end

  test "should execute task first time" do
    set_current_time
    expect_execution
    task = create_task

    assert_equal :handler_success, task.perform
    assert_equal base_time, task.last_run
  end

  test "should execute task after interval time" do
    set_current_time base_time + 60
    task = create_task base_time
    expect_execution

    assert_equal :handler_success, task.perform
    assert_equal base_time + 60, task.last_run
  end

  test "should execute task after interval time minus tolerance" do
    set_current_time base_time + 55
    task = create_task base_time
    expect_execution

    assert_equal :handler_success, task.perform
    assert_equal base_time + 55, task.last_run
  end

  test "should execute task after more than interval time" do
    set_current_time base_time + 95
    task = create_task base_time
    expect_execution

    assert_equal :handler_success, task.perform
    assert_equal base_time + 95, task.last_run
  end

  test "should not execute task within interval time" do
    set_current_time base_time + 45
    task = create_task base_time
    expect_execution 0

    assert_equal :dropped, task.perform
    assert_equal base_time, task.last_run
  end

  test "should not execute second task when first one is still executing" do
    expect_execution 1

    set_current_time base_time + 1
    task = create_task base_time, create_handler, 1, 2
    th = Thread.start do
      assert_equal :handler_success, task.perform
    end
    sleep 1
    task2 = CronTask.find_by_id(task.id)
    assert_equal :dropped, task2.perform
    task2.reload
    assert_not_nil task2.locked_tag
    th.join
  end

  def create_task(last_run=nil, handler=create_handler, interval = 60, sleep_time = 0)
    task = CronTask.new :interval => interval, :last_run => last_run
    handler.sleep_time = sleep_time if sleep_time > 0
    task.set_handler(handler)
    assert task.save!
    task
  end

  def create_handler(quota=nil, arg=:arg)
    h = Handler.new arg
    h.expects(:quota=).with(quota) unless quota.nil?
    return h
  end

  def expect_execution(times=1, arg=:arg)
    Witness.expects(:execute).with(arg).times(times)
  end

  def clean_database
    [
      Account, Log,
      AddressSource, AoMessage, Application,
      AtMessage, Carrier, Channel,
      ClickatellCoverageMO, ClickatellMessagePart, Country,
      CronTask, MobileNumber,
      QstOutgoingMessage, SmppMessagePart,
      TwitterChannelStatus, WorkerQueue
    ].each(&:delete_all)
  end

  class Handler
    attr_accessor :sleep_time
    def initialize(arg)
      @arg = arg
    end
    def perform
      sleep sleep_time if !sleep_time.nil? && sleep_time > 0
      Witness.execute @arg
      return :handler_success
    end
  end

  class Witness
  end

end
