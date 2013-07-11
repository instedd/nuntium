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

class ShujaaControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @application = Application.make :account => @account, :password => 'secret'
    @chan = ShujaaChannel.make :account => @account
  end

  test "index" do
    get :index, :source => "1234", :destination => "5678", :message => "Hello", :messageId => "0123", :network => "safaricom", :callback_guid => @chan.callback_guid, :account_id => @account.id

    assert_response :ok

    msgs = AtMessage.all
    assert_equal 1, msgs.length

    msg = msgs[0]
    assert_equal @account.id, msg.account_id
    assert_equal @chan.id, msg.channel_id
    assert_equal "sms://1234", msg.from
    assert_equal "sms://5678", msg.to
    assert_equal "Hello", msg.body
    assert_equal "0123", msg.channel_relative_id
    assert_equal "safaricom", msg.custom_attributes['network']
    assert_equal 'queued', msg.state
  end

end
