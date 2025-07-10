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

class SendTwilioMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = TwilioChannel.make_unsaved
    def @chan.configure_phone_number
      self.incoming_password = Devise.friendly_token
      true
    end
    @chan.save!
    @config = @chan.configuration
    stub_twilio
    @msg = AoMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2', :subject => "a subject", :body => "a body"
  end

  should "perform" do
    response = {'sid' => 'sms_sid'}
    @twilio_client.expects(:create_sms).returns(response)

    deliver @msg

    msg = AoMessage.first
    assert_equal 'sms_sid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  should "perform error" do
    @twilio_client.expects(:create_sms).raises(RestClient::BadRequest.new('{"status": 503}'))

    deliver @msg

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state

    @chan.reload
    assert @chan.enabled
  end

  should "perform authenticate error" do
    @twilio_client.expects(:create_sms).raises(RestClient::BadRequest.new('{"status": 401}'))

    begin
      deliver @msg
    rescue => e
    else
      fail "Expected exception to be thrown"
    end

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'queued', msg.state

    @chan.reload
    assert_false @chan.enabled
  end

  should "perform with expected parameters" do
    response = {'sid' => 'sms_sid'}

    @twilio_client.expects(:create_sms).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == "+#{@msg.to.without_protocol}" &&
      params[:body] == @msg.subject_and_body
    end.returns(response)

    deliver @msg
  end

  should "perform with callback url" do
    NamedRoutes.expects(:twilio_ack_url).returns('http://nuntium/foo/twilio/ack')

    response = {'sid' => 'sms_sid'}

    @twilio_client.expects(:create_sms).with do |params|
      params[:status_callback] == "http://#{@chan.name}:#{@config[:incoming_password]}@nuntium/foo/twilio/ack"
    end.returns(response)

    deliver @msg
  end

  should "perform with long messages" do
    long_msg = AoMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2', :subject => nil, :body => ("a" * 160 + "b" * 40)

    # First part of the message
    response = {'sid' => 'sms_sid'}
    @twilio_client.expects(:create_sms).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == "+#{long_msg.to.without_protocol}" &&
      params[:body] == "a" * 160
    end.returns(response)

    # Second part
    @twilio_client.expects(:create_sms).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == "+#{long_msg.to.without_protocol}" &&
      params[:body] == "b" * 40
    end

    deliver long_msg

    long_msg.reload
    assert_equal 'sms_sid', long_msg.channel_relative_id
    assert_equal 1, long_msg.tries
    assert_equal 'delivered', long_msg.state
  end

  def deliver(msg)
    job = SendTwilioMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def stub_twilio
    @twilio_client = mock('TwilioClient')
    TwilioClient.expects(:new).with(@config[:account_sid], @config[:auth_token]).returns(@twilio_client)
  end

end
