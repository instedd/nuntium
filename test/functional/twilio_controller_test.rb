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

class TwilioControllerTest < ActionController::TestCase
  def setup
    @user = User.make!
    @account = @user.create_account Account.make
    sign_in @user
    @application = @account.applications.make! :password => 'secret'
    @chan = @account.twilio_channels.make
    def @chan.configure_phone_number
      self.incoming_password = Devise.friendly_token
      true
    end
    @chan.save!
  end

  test "receive message" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}

    post :index, message.merge(:account_id => @account.name)

    assert_response :ok
    assert_message message
  end

  test "receive message in USA without country code" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '2343839922', :To => '4567772222', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid],
      :FromCountry => 'US', :ToCountry => 'US'}

    post :index, message.merge(:account_id => @account.name)

    assert_response :ok
    assert_message message.merge(:From => '12343839922', :To => '14567772222')
  end

  test "receive message in USA with +1" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '+12343839922', :To => '+14567772222', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid],
      :FromCountry => 'US', :ToCountry => 'US'}

    post :index, message.merge(:account_id => @account.name)

    assert_response :ok
    assert_message message.merge(:From => '12343839922', :To => '14567772222')
  end

  test "receive confirmed ack" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    msg = AoMessage.make! :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'sms_sid'

    post :ack, :account_id => @account.name, :SmsStatus => 'sent', :AccountSid => @chan.configuration[:account_sid], :SmsSid => 'sms_sid'

    assert_response :ok
    assert_equal 'confirmed', msg.reload.state
  end

  test "receive failed ack" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    msg = AoMessage.make! :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'sms_sid'

    post :ack, :account_id => @account.name, :SmsStatus => 'failed', :AccountSid => @chan.configuration[:account_sid], :SmsSid => 'sms_sid'

    assert_response :ok
    assert_equal 'failed', msg.reload.state
  end

  test "fails authorization because of account" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => 'another')
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  test "fails authorization because of incoming password" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming2')
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  test "fails authorization because of account sid" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => 'another account sid'}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  test "fails authorization because of channel name" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth('another channel name', @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, AtMessage.count
  end

  def assert_message message
    msgs = AtMessage.all
    assert_equal 1, msgs.length

    msg = msgs[0]
    assert_equal @account.id, msg.account_id
    assert_equal "sms://#{message[:From]}", msg.from
    assert_equal "sms://#{message[:To]}", msg.to
    assert_equal message[:Body], msg.body
    assert_equal message[:SmsSid], msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end

end
