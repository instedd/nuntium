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

class ClickatellControllerTest < ActionController::TestCase
  def setup
    @user = User.make!
    @account = @user.create_account Account.make
    sign_in @user
    @application = Application.make! :account => @account, :password => 'secret'
    @chan = ClickatellChannel.make :account => @account
    @chan.configuration[:incoming_password] = 'incoming'
    @chan.save!
  end

  def assert_message(options = {})
    assert_equal 0, ClickatellMessagePart.all.length

    msgs = AtMessage.all
    assert_equal 1, msgs.length

    msg = msgs[0]
    assert_equal @account.id, msg.account_id
    assert_equal "sms://#{options[:from]}", msg.from
    assert_equal "sms://#{options[:to]}", msg.to
    assert_equal options[:body], msg.body
    assert_equal Time.parse('2009-12-16 17:34:40 UTC'), msg.timestamp
    assert_equal options[:channel_relative_id], msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end

  test "index" do
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '', 'some text', '5223433'
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])

    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok

    assert_message :from => from, :to => to, :body => text, :channel_relative_id => mo_msg_id
  end

  [:normal_order, :inverted_order].each do |order|
    test "two parts #{order}" do
      from, to = '442345235413', '61234234231'
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])

      2.times do |time|
        if (time == 0 and order == :normal_order) or (time == 1 and order == :inverted_order)
          api_id, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id], '2009-12-16 19:34:40', 'ISO-8859-1', '050003050201', 'Hello ', '1'
          get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
          assert_response :ok
        else
          api_id, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id], '2009-12-16 19:34:40', 'ISO-8859-1', '050003050202', 'world', '2'
          get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
          assert_response :ok
        end
      end

      assert_message :from => from, :to => to, :body => 'Hello world', :channel_relative_id => (order == :normal_order ? '2' : '1')
    end
  end

  test "ignore message headers" do
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050202', 'Hello ', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok

    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050201', 'world', '1'
    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok

    assert_equal 0, ClickatellMessagePart.all.length

    msgs = AtMessage.all
    assert_equal 2, msgs.length
  end

  test "fails authorization because of account" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    get :index, :account_id => 'another', :api_id => @chan.configuration[:api_id], :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  test "fails authorization because of channel" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming2')
    get :index, :account_id => @account.name, :api_id => @chan.configuration[:api_id], :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  test "ack just to verify" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    get :ack, :account_id => @account.name
    assert_response :ok
  end

  test "ack 003 (delivered to gateway)" do
    @msg = AoMessage.make! :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'foo'

    charge = 0.3
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    get :ack, :account_id => @account.name, :apiMsgId => @msg.channel_relative_id, :charge => charge, :status => '003'
    assert_response :ok

    @msg.reload

    assert_equal (@chan.configuration[:cost_per_credit].to_f * charge).round(2), @msg.custom_attributes[:cost].to_f
  end

  test "ack 004 (received by recipient)" do
    @msg = AoMessage.make! :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'foo'

    charge = 0.3
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    get :ack, :account_id => @account.name, :apiMsgId => @msg.channel_relative_id, :charge => charge, :status => '004'
    assert_response :ok

    @msg.reload

    assert_equal 'confirmed', @msg.state
  end

  ['005', '006', '007', '012'].each do |status|
    test "ack #{status} (failed)" do
      @msg = AoMessage.make! :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'foo'

      charge = 0.3
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
      get :ack, :account_id => @account.name, :apiMsgId => @msg.channel_relative_id, :charge => charge, :status => status
      assert_response :ok

      @msg.reload

      assert_equal 'failed', @msg.state
    end
  end

  test "view credit" do
    Clickatell.expects(:get_credit).with(:api_id => @chan.api_id, :user => @chan.user, :password => @chan.password).returns('xxx')
    get :view_credit, :id => @chan.id

    assert_equal 'xxx', @response.body
  end

end
