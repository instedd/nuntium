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

class SendTwitterMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  def setup
    @channel = TwitterChannel.make!
    @msg = AoMessage.make! :account_id => @channel.account_id, :channel_id => @channel.id, :state => 'queued'
    @job = SendTwitterMessageJob.new @channel.account_id, @channel.id, @msg.id
  end

  test "send" do
    response = mock('response')
    response.stubs :id => 'twitter_id'

    client = mock('client')
    client.expects(:direct_message_create).with(@msg.to.without_protocol, @msg.subject_and_body).returns(response)

    TwitterChannel.expects(:new_authorized_client).with(@channel.token, @channel.secret, TwitterChannel.consumer_key, TwitterChannel.consumer_secret).returns(client)

    @job.perform

    @msg.reload
    assert_equal 'delivered', @msg.state
    assert_equal response.id, @msg.channel_relative_id
  end

  test "send unauthorized" do
    client = mock('client')
    client.expects(:direct_message_create).with(@msg.to.without_protocol, @msg.subject_and_body).raises(Twitter::Error::Unauthorized.new(''))

    TwitterChannel.expects(:new_authorized_client).with(@channel.token, @channel.secret, TwitterChannel.consumer_key, TwitterChannel.consumer_secret).returns(client)

    begin
      @job.perform
    rescue
    else
      fail "Exepcted exception to be thrown"
    end

    @channel.reload
    assert_false @channel.enabled
  end
end
