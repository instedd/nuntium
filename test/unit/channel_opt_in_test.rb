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

class ChannelOptInTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make :priority => 1
    @chan.opt_in_enabled = true
    @chan.opt_in_keyword = 'in'
    @chan.opt_in_message = 'in message'
    @chan.opt_out_keyword = 'out'
    @chan.opt_out_message = 'out message'
    @chan.opt_help_keyword = 'help'
    @chan.opt_help_message = 'help message'
    @chan.save!

    @chan2 = QstServerChannel.make! :account => @chan.account, :priority => 2

    @app = Application.make! account: @chan.account
  end

  test "replies help message for opt-in help keyword" do
    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'help'
    @chan.route_at msg

    msg.reload

    assert_equal 'replied', msg.state
    assert_nil msg.application_id

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @chan.account_id, msgs[0].account_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal msg.to, msgs[0].from
    assert_equal msg.from, msgs[0].to
    assert_equal @chan.opt_help_message, msgs[0].body
  end

  test "doesn't reply help message for opt-in help keyword if opt in is disabled" do
    @chan.opt_in_enabled = false

    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'help'
    @chan.route_at msg

    msg.reload

    assert_equal 'queued', msg.state

    assert_equal 0, AoMessage.count
  end

  test "discards ao if not in whitelist" do
    msg = AoMessage.new :account_id => @chan.account_id, :from => 'sms://1', :to => 'sms://2', :body => 'hello'
    @app.route_ao msg, 'test'

    msg.reload

    assert_equal @chan2.id, msg.channel_id
  end

  test "takes ao into account if in whitelist" do
    @chan.add_to_whitelist 'sms://2'

    msg = AoMessage.new :account_id => @chan.account_id, :from => 'sms://1', :to => 'sms://2', :body => 'hello'
    @app.route_ao msg, 'test'

    msg.reload

    assert_equal @chan.id, msg.channel_id
  end

  test "adds to whitelist if message is opt-in" do
    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'in'
    @chan.route_at msg

    msg.reload

    assert_equal 'replied', msg.state
    assert_nil msg.application_id

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @chan.account_id, msgs[0].account_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal msg.to, msgs[0].from
    assert_equal msg.from, msgs[0].to
    assert_equal @chan.opt_in_message, msgs[0].body

    assert_equal 1, @chan.whitelists.where(account_id: @chan.account_id, address: 'sms://1').count
  end

  test "routes to app if message is opt-in but already in whitelist" do
    @chan.add_to_whitelist 'sms://1'

    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'in'
    @chan.route_at msg

    msg.reload

    assert_equal 'queued', msg.state
    assert_equal @chan.id, msg.channel_id

    assert_equal 0, AoMessage.count
  end

  test "removes from whitelist if message is opt-out" do
    @chan.add_to_whitelist 'sms://1'

    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'out'
    @chan.route_at msg

    msg.reload

    assert_equal 'replied', msg.state
    assert_nil msg.application_id

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @chan.account_id, msgs[0].account_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal msg.to, msgs[0].from
    assert_equal msg.from, msgs[0].to
    assert_equal @chan.opt_out_message, msgs[0].body

    assert_equal 0, @chan.whitelists.where(account_id: @chan.account_id, address: 'sms://1').count
  end

  test "removes from whitelist if message is opt-out but not in whitelist" do
    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'out'
    @chan.route_at msg

    msg.reload

    assert_equal 'replied', msg.state
    assert_nil msg.application_id

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @chan.account_id, msgs[0].account_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal msg.to, msgs[0].from
    assert_equal msg.from, msgs[0].to
    assert_equal @chan.opt_out_message, msgs[0].body

    assert_equal 0, @chan.whitelists.where(account_id: @chan.account_id, address: 'sms://1').count
  end
end
