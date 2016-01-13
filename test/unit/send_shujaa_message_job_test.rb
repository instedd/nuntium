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

class SendShujaaMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = ShujaaChannel.make!
    @kenya = Country.make!
    @safaricom = @kenya.carriers.make! guid: ShujaaChannel::SAFARICOM
    @airtel = @kenya.carriers.make! guid: ShujaaChannel::AIRTEL
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :body => '1234:0')

    msg = AoMessage.make! :account => @chan.account, :channel => @chan
    msg.country = @kenya.iso2
    msg.carrier = @safaricom.guid
    msg.save!

    expect_rest msg, response, :network => 'safaricom'

    deliver msg

    msg = AoMessage.first
    assert_equal '1234', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  should "perform with zero prefix" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :body => '1234:0')

    msg = AoMessage.make! :account => @chan.account, :channel => @chan, :to => '0720123456'

    expect_rest msg, response, :destination => '254720123456'

    deliver msg

    msg = AoMessage.first
    assert_equal '1234', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  should "perform and get message error" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :body => '0:2')

    msg = AoMessage.make! :account => @chan.account, :channel => @chan

    expect_rest msg, response

    deliver msg

    msg = AoMessage.first
    assert_equal nil, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state

    logs = Log.all
    assert_equal 1, logs.length
    assert logs[0].message =~ %r(#{Regexp.escape ShujaaChannel::SHUJAA_ERRORS[2][:description]})
  end

  def expect_rest(msg, response, overrides = {})
    params = {}
    params[:username] = @chan.username
    params[:password] = @chan.password
    params[:account] = @chan.shujaa_account
    params[:source] = @chan.address
    params[:destination] = msg.to.without_protocol
    params[:message] = msg.subject_and_body

    params.merge!(overrides)

    RestClient.expects(:get).with("http://sms.shujaa.mobi/sendsms?#{params.to_query}").returns(response)
  end

  def deliver(msg)
    job = SendShujaaMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end
end
