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

class SendMultimodemIsmsMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = MultimodemIsmsChannel.make
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :body => 'ID: msgid')

    msg = AoMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'

    expect_rest msg, response
    deliver msg

    msg = AoMessage.first
    assert_equal 'msgid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  def expect_rest(msg, response)
    params = ""
    params << "user=#{CGI.escape(@chan.configuration[:user])}&"
    params << "passwd=#{CGI.escape(@chan.configuration[:password])}&"
    params << "cat=1&"
    params << "to=#{CGI.escape(msg.to.without_protocol)}&"
    params << "text=#{CGI.escape(msg.subject_and_body)}"

    RestClient.expects(:get).with("http://#{@chan.configuration[:host]}:#{@chan.configuration[:port]}/sendmsg?#{params}").returns(response)
  end

  def deliver(msg)
    job = SendMultimodemIsmsMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def check_message_was_delivered(channel_relative_id)
    msg = AoMessage.first
    assert_equal channel_relative_id, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end
