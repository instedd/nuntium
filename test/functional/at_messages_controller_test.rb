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

class AtMessagesControllerTest < ActionController::TestCase
  def setup
    @user = User.make
    @account = @user.create_account Account.make_unsaved
    sign_in @user
    @chan = QstServerChannel.make :account => @account
    @application = Application.make :account => @account, :password => 'app_pass'

    @at_msg1 = AtMessage.create! :account_id => @account.id, :state => 'queued', :body => 'one'
    @at_msg2 = AtMessage.create! :account_id => @account.id, :state => 'queued', :body => 'one'
    @at_msg3 = AtMessage.create! :account_id => @account.id, :state => 'queued', :body => 'two'

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
  end

  def assert_fields(kind, member, *states)
    msgs = (kind == :ao ? AoMessage : AtMessage).all
    assert_equal states.length, msgs.length
    states.length.times do |i|
      assert_equal states[i], msgs[i].send(member)
    end
  end

  test "mark at messages as cancelled" do
    post :mark_as_cancelled, :at_messages => [@at_msg1.id, @at_msg2.id]

    assert_redirected_to at_messages_path(:at_messages => [@at_msg1.id, @at_msg2.id])
    assert_equal '2 Application Terminated messages were marked as cancelled', flash[:notice]

    assert_fields :at, :state, 'cancelled', 'cancelled', 'queued'
  end

  test "mark at messages as cancelled using search" do
    post :mark_as_cancelled, :at_all => 1, :search => 'one'

    assert_redirected_to at_messages_path(:at_all => 1, :search => 'one')
    assert_equal '2 Application Terminated messages were marked as cancelled', flash[:notice]

    assert_fields :at, :state, 'cancelled', 'cancelled', 'queued'
  end
end
