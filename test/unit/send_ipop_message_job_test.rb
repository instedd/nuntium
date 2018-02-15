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

class SendIpopMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = IpopChannel.make!
    @msg = AoMessage.make! :account => Account.make!, :channel => @chan, :timestamp => Time.utc(2001, 02, 03, 04, 05, 06)
    @query = {
      :sc => @chan.address,
      :hp => @msg.to.mobile_number,
      :ts => '20010203040506000',
      :cid => @chan.configuration[:cid],
      :bid => @chan.configuration[:bid],
      :mt => 1,
      :txt => @msg.subject_and_body
    }
  end

  test "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :read_body => 'OK')

    expect_post :url => @chan.configuration[:mt_post_url],
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => 'OK'

    deliver

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
    assert_equal "#{@msg.to.mobile_number}-#{@query[:ts]}", msg.channel_relative_id
  end

  def deliver
    job = SendIpopMessageJob.new(@chan.account.id, @chan.id, @msg.id)
    job.perform
  end
end
