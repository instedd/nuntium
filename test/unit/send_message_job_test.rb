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

class SendMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "should rethrow on permanent exception" do
    account = Account.make!
    channel = QstServerChannel.make! :account => account
    msg = AoMessage.make! :account => account, :channel => channel, :state => 'queued'

    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).raises(PermanentException.new(Exception.new('ex')))

    begin
      job.perform
    rescue => ex
      exception = ex
    else
      fail "Expected exception to be thrown"
    end

    job.reschedule exception

    msg.reload
    assert_equal 'delayed', msg.state

    sjobs = ScheduledJob.all
    assert_equal 1, sjobs.length

    republish = sjobs.first.job
    assert_true republish.kind_of?(RepublishAoMessageJob)
    assert_equal msg.id, republish.message_id
    job = republish.job
    assert_true job.kind_of?(SendMessageJob)
    assert_equal account.id, job.account_id
    assert_equal channel.id, job.channel_id
    assert_equal msg.id, job.message_id

    channel.reload
    assert_false channel.enabled
  end

  test "should increment tries on temporary exception" do
    account = Account.make!
    channel = QstServerChannel.make! :account => account
    msg = AoMessage.make! :account => account, :channel => channel, :state => 'queued'

    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).raises(Exception.new('ex'))

    begin
      job.perform
    rescue Exception => ex
    else
      fail 'Should have re-thrown the exception'
    end

    msg.reload
    assert_equal 1, msg.tries
  end

  test "should not execute if the message is queued on a different channel" do
    account = Account.make!
    channel1 = QstServerChannel.make! :account => account
    channel2 = QstServerChannel.make! :account => account
    msg = AoMessage.make! :account => account, :channel => channel2

    job = SendMessageJob.new account.id, channel1.id, msg.id
    job.expects(:managed_perform).never

    assert_true job.perform
  end

  test "should not execute if the message is not in 'queued' state" do
    account = Account.make!
    channel = QstServerChannel.make! :account => account
    msg = AoMessage.make! :account => account, :channel => channel, :state => 'canceled'

    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).never

    assert_true job.perform
  end
end
