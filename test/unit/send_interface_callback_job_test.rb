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

class SendInterfaceCallbackJobTest < ActiveSupport::TestCase
  def setup
    @application = Application.make
    @chan = QstServerChannel.make :account => @application.account, :application => @application
    @msg = AtMessage.make :account => @application.account, :application => @application, :channel => @chan
    @query = {
      :application => @application.name,
      :from => @msg.from,
      :to => @msg.to,
      :subject => @msg.subject,
      :body => @msg.body,
      :guid => @msg.guid,
      :channel => @chan.name
    }
  end

  test "get" do
    @application.interface = 'http_get_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_get :url => @application.interface_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "get with auth" do
    @application.interface = 'http_get_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.interface_user = 'john'
    @application.interface_password = 'pass'
    @application.save!

    expect_get :url => @application.interface_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}, :user => @application.interface_user, :password => @application.interface_password},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post with auth" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.interface_user = 'john'
    @application.interface_password = 'pass'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}, :user => @application.interface_user, :password => @application.interface_password},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post unauthorized" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPUnauthorized

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    begin
      job.perform
    rescue => ex
      exception = ex
    else
      fail "Expected exception to be thrown"
    end

    job.reschedule exception

    @msg.reload
    assert_equal 'delayed', @msg.state

    sjobs = ScheduledJob.all
    assert_equal 1, sjobs.length

    republish = sjobs.first.job.deserialize_job
    assert_true republish.kind_of?(RepublishAtJob)
    assert_equal @application.id, republish.application_id
    assert_equal @msg.id, republish.message_id

    job = republish.job
    assert_true job.kind_of?(SendInterfaceCallbackJob)
    assert_equal @application.account.id, job.account_id
    assert_equal @application.id, job.application_id
    assert_equal @msg.id, job.message_id
    assert_equal 1, job.tries

    @application.reload
    assert_equal 'http_post_callback', @application.interface
  end

  test "post bad request" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPBadRequest

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    @application.reload
    assert_equal 'http_post_callback', @application.interface

    @msg.reload

    assert_equal 'failed', @msg.state
    assert_equal 1, @msg.tries
  end

  test "discard not queued messages" do
    expect_no_rest

    @msg.state = 'cancelled'
    @msg.save!

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post response is a text, route it back" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => 'foo',
      :returns_content_type => 'text/plain'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal @application.account_id, msgs[0].account_id
    assert_equal @application.id, msgs[0].application_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal @msg.to, msgs[0].from
    assert_equal @msg.from, msgs[0].to
    assert_equal 'foo', msgs[0].body
    assert_equal @msg.token, msgs[0].token
  end

  test "post response is a json array, route it back" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => [{:from => 'sms://1', :to => 'sms://2', :body => 'Hello!', :country => 'ar'}].to_json,
      :returns_content_type => 'application/json'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal @application.account_id, msgs[0].account_id
    assert_equal @application.id, msgs[0].application_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal 'sms://1', msgs[0].from
    assert_equal 'sms://2', msgs[0].to
    assert_equal 'Hello!', msgs[0].body
    assert_equal 'ar', msgs[0].country
    assert_equal @msg.token, msgs[0].token
  end

  test "post response is a json hash, route it back" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => {:from => 'sms://1', :to => 'sms://2', :body => 'Hello!', :country => 'ar'}.to_json,
      :returns_content_type => 'application/json'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal @application.account_id, msgs[0].account_id
    assert_equal @application.id, msgs[0].application_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal 'sms://1', msgs[0].from
    assert_equal 'sms://2', msgs[0].to
    assert_equal 'Hello!', msgs[0].body
    assert_equal 'ar', msgs[0].country
    assert_equal @msg.token, msgs[0].token
  end

  test "post response is a json hash with token" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => {:token => 'my_token'}.to_json,
      :returns_content_type => 'application/json'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal 'my_token', msgs[0].token
  end

  test "post response is an xml, route it back" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    xml = AoMessage.make_unsaved :subject => nil
    xml.country = 'ar'

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => AoMessage.write_xml([xml]),
      :returns_content_type => 'application/xml'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal @application.account_id, msgs[0].account_id
    assert_equal @application.id, msgs[0].application_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal xml.from, msgs[0].from
    assert_equal xml.to, msgs[0].to
    assert_equal xml.body, msgs[0].body
    assert_equal xml.country, msgs[0].country
    assert_equal @msg.token, msgs[0].token
  end

  test "post response is an xml with a token" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    xml = AoMessage.make_unsaved :subject => nil
    xml.token = 'my_token'

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => AoMessage.write_xml([xml]),
      :returns_content_type => 'application/xml'

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform

    msgs = AoMessage.all
    assert_equal 1, msgs.count
    assert_equal 'my_token', msgs[0].token
  end

  test "post with custom attributes" do
    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.save!

    @msg.country = 'ar'
    @msg.carrier = 'some_guid'
    @msg.save!

    @query['country'] = 'ar'
    @query['carrier'] = 'some_guid'

    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "get with custom format" do
    @msg.country = 'ar'
    @msg.save!

    @application.interface = 'http_get_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.interface_custom_format = "text=${body}&num=${from}&num2=${from_without_protocol}&country=${country}"
    @application.save!

    expect_get :url => @application.interface_url,
      :query_params => "text=#{CGI.escape @msg.body}&num=#{CGI.escape @msg.from}&num2=#{CGI.escape @msg.from.without_protocol}&country=ar",
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post with custom format" do
    @msg.country = 'ar'
    @msg.save!

    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.interface_custom_format = "text=${body}&num=${from}&num2=${from_without_protocol}&country=${country}"
    @application.save!

    expect_post :url => @application.interface_url,
      :data => "text=#{@msg.body}&num=#{@msg.from}&num2=#{@msg.from.without_protocol}&country=ar",
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end

  test "post with custom format is xml" do
    @msg.body = '<hello>'
    @msg.country = 'ar'
    @msg.save!

    @application.interface = 'http_post_callback'
    @application.interface_url = 'http://www.domain.com'
    @application.interface_custom_format = "<foo>${body}</foo>"
    @application.save!

    expect_post :url => @application.interface_url,
      :data => "<foo>#{@msg.body.to_xs}</foo>",
      :options => {:headers => {:content_type => "application/xml"}},
      :returns => Net::HTTPSuccess

    job = SendInterfaceCallbackJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end
end
