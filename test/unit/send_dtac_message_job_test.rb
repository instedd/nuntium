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

class SendDtacMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = DtacChannel.make
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :read_body => 'Status=0')

    msg = AoMessage.make :account => Account.make, :channel => @chan

    expect_http_post msg, response
    deliver msg

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  should "perform error" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :read_body => 'Status=-111') # Message length too long

    msg = AoMessage.make :account => Account.make, :channel => @chan

    expect_http_post msg, response
    deliver msg

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state

    logs = Log.all
    assert_equal 1, logs.length
    assert_true logs[0].message.include?('111. Message length exceed 1000 characters: The length of parameter "Msg" is over than 1000 characters')

    @chan.reload
    assert_true @chan.enabled
  end

  should "perform fatal error" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :read_body => 'Status=-110') # Invalid User / Invalid Password: Not valid User or Password

    msg = AoMessage.make :account => Account.make, :channel => @chan

    expect_http_post msg, response
    begin
      deliver msg
    rescue
    else
      fail "Expected exception to be thrown"
    end

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'queued', msg.state

    @chan.reload
    assert_true @chan.enabled
  end

  def expect_http_post(msg, response)
    encoded = ActiveSupport::Multibyte::Chars.u_unpack(msg.subject_and_body).map { |i| i.to_s(16).rjust(4, '0') }
    Net::HTTP.expects(:post_form).with do |uri, params|
      params['Msn'] == msg.to.without_protocol &&
      params['Sno'] == msg.from.without_protocol &&
      params['Sender'] == msg.from.without_protocol &&
      params['Msg'] == encoded.to_s &&
      params['Encoding'] == 25 &&
      params['MsgType'] == 'H' &&
      params['User'] == @chan.configuration[:user] &&
      params['Password'] == @chan.configuration[:password]
    end.returns(response)
  end

  def deliver(msg)
    job = SendDtacMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def check_message_was_delivered(channel_relative_id)
    msg = AoMessage.first
    assert_equal channel_relative_id, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end
