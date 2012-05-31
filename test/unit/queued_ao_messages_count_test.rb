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

class QueuedAoMessagesCountTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make
  end

  test "default count is zero" do
    assert_equal 0, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  test "when an ao gets queued count gets incremented" do
    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]

    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 2, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  test "when an ao gets out of queued count gets decremented" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]

    msg.state = 'delivered'
    msg.save!

    assert_equal 0, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  test "when an ao does not change its state count is the same" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]

    msg.tries = 2
    msg.save!

    assert_equal 1, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  test "when an ao gets created but it's not queued don't increment" do
    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'
    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'
    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'

    assert_equal 0, @chan.account.queued_ao_messages_count_by_channel_id[@chan.id]
  end
end
