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

class NexmoControllerTest < ActionController::TestCase
  def setup
    @user = User.make
    @account = @user.create_account Account.make_unsaved
    @application = Application.make :account => @account, :password => 'secret'
    @chan = NexmoChannel.make :account_id => @account.id
  end

  test "ack delivered" do
    ao = AoMessage.make_unsaved :account_id => @account.id, :channel_id => @chan.id
    ao.channel_relative_id = "1234"
    ao.save!

    get :ack, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :status => "ACCEPTED", :"err-code" => "1", :price => "12.34"
    assert_equal 200, response.status

    ao.reload
    assert_equal "delivered", ao.state
    assert_equal "accepted", ao.custom_attributes["nexmo_delivery_status"]
    assert_equal nil, ao.custom_attributes["nexmo_delivery_err_code"]
    assert_equal "12.34", ao.custom_attributes["nexmo_delivery_price"]
  end

  test "ack confirmed" do
    ao = AoMessage.make_unsaved :account_id => @account.id, :channel_id => @chan.id
    ao.channel_relative_id = "1234"
    ao.save!

    get :ack, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :status => "DELIVERED", :"err-code" => "0", :price => "12.34"
    assert_equal 200, response.status

    ao.reload
    assert_equal "confirmed", ao.state
    assert_equal "delivered", ao.custom_attributes["nexmo_delivery_status"]
  end

  test "ack buffered" do
    ao = AoMessage.make_unsaved :account_id => @account.id, :channel_id => @chan.id
    ao.channel_relative_id = "1234"
    ao.save!

    get :ack, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :status => "BUFFERED", :"err-code" => "0", :price => "12.34"
    assert_equal 200, response.status

    ao.reload
    assert_equal "queued", ao.state
    assert_equal "buffered", ao.custom_attributes["nexmo_delivery_status"]
  end

  test "ack failed" do
    ao = AoMessage.make_unsaved :account_id => @account.id, :channel_id => @chan.id
    ao.channel_relative_id = "1234"
    ao.save!

    get :ack, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :status => "FAILED", :"err-code" => "1"
    assert_equal 200, response.status

    ao.reload
    assert_equal "failed", ao.state
    assert_equal "failed", ao.custom_attributes["nexmo_delivery_status"]
    assert_equal "1", ao.custom_attributes["nexmo_delivery_err_code"]
  end

  test "incoming" do
    get :incoming, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :text => "hello",
      :type => "text", :msisdn => "2345", :to => "3456", :concat => "false"
    assert_equal 200, response.status

    ats = AtMessage.all
    assert_equal 1, ats.size

    at = ats[0]
    assert_equal @account.id, at.account_id
    assert_equal @chan.id, at.channel_id
    assert_equal "1234", at.channel_relative_id
    assert_equal "hello", at.body
    assert_equal "sms://2345", at.from
    assert_equal "sms://3456", at.to
    assert_equal "queued", at.state
  end

  test "incoming multi-part" do
    get :incoming, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :text => "hello",
      :type => "text", :msisdn => "2345", :to => "3456", :concat => "TRUE",
      :"concat-total" => "3", :"concat-ref" => "xyzw", :"concat-part" => "1"
    assert_equal 200, response.status

    ats = AtMessage.all
    assert_equal 1, ats.size

    at = ats[0]
    assert_equal @account.id, at.account_id
    assert_equal @chan.id, at.channel_id
    assert_equal "xyzw", at.channel_relative_id
    assert_equal "sms://2345", at.from
    assert_equal "sms://3456", at.to
    assert_equal nil, at.body
    assert_equal ["hello", nil, nil], at.custom_attributes["nexmo_parts"]
    assert_equal "pending", at.state

    get :incoming, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :text => "!",
      :type => "text", :msisdn => "2345", :to => "3456", :concat => "TRUE",
      :"concat-total" => "3", :"concat-ref" => "xyzw", :"concat-part" => "3"
    assert_equal 200, response.status

    ats = AtMessage.all
    assert_equal 1, ats.size

    at = ats[0]
    assert_equal ["hello", nil, "!"], at.custom_attributes["nexmo_parts"]
    assert_equal nil, at.body
    assert_equal "pending", at.state

    get :incoming, :account_id => @account.id, :channel_id => @chan.id, :callback_token => @chan.callback_token, :messageId => "1234", :text => " world",
      :type => "text", :msisdn => "2345", :to => "3456", :concat => "TRUE",
      :"concat-total" => "3", :"concat-ref" => "xyzw", :"concat-part" => "2"
    assert_equal 200, response.status

    ats = AtMessage.all
    assert_equal 1, ats.size

    at = ats[0]
    assert_equal "hello world!", at.body
    assert_equal nil, at.custom_attributes["nexmo_parts"]
    assert_equal "1234", at.channel_relative_id
    assert_equal "queued", at.state
  end
end
