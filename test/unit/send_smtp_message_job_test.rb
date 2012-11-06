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
require 'net/smtp'

class SendSmtpMessageJobTest < ActiveSupport::TestCase
  def setup
    @time = Time.now
    @chan = SmtpChannel.make
  end

  test "perform no ssl" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan
    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    deliver msg
    expect_ao_message_was_delivered
  end

  test "perform without user and password" do
    @chan.configuration[:user] = @chan.configuration[:password] = nil
    @chan.save!

    msg = AoMessage.make :account => @chan.account, :channel => @chan
    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    deliver msg
    expect_ao_message_was_delivered
  end

  test "perform ssl" do
    @chan.configuration[:use_ssl] = '1'
    @chan.save!

    msg = AoMessage.make :account => @chan.account, :channel => @chan
    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    deliver msg
    expect_ao_message_was_delivered
  end

  test "perform with thread" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan
    msg.custom_attributes['references_thread'] = 'foo'
    msg.save!

    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    deliver msg
    expect_ao_message_was_delivered
  end

  test "perform with references" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan
    msg.custom_attributes['references_foo'] = 'a'
    msg.custom_attributes['references_bar'] = 'b'
    msg.save!

    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    deliver msg
    expect_ao_message_was_delivered
  end

  def msg_as_email(msg)
    s = ""
    s << "From: #{msg.from.without_protocol}\n"
    s << "To: #{msg.to.without_protocol}\n"
    s << "Subject: #{msg.subject}\n"
    s << "Date: #{msg.timestamp}\n"
    s << "Message-Id: <#{msg.guid}@message_id.nuntium>\n"
    s << "References: <#{msg.guid}@message_id.nuntium>"
    msg.custom_attributes.each do |key, value|
      next unless key.start_with?('references_')
      s << ", <#{value}@#{key[11 .. -1]}.nuntium>"
    end
    s << "\n"
    s << "\n"
    s << msg.body
    s.strip
  end

  def expect_smtp(msg, msgstr)
    smtp = mock('Net::SMTP')
    Net::SMTP.expects(:new).with(@chan.configuration[:host], @chan.configuration[:port]).returns(smtp)
    smtp.expects(:enable_tls) if @chan.configuration[:use_ssl].to_b
    if @chan.configuration[:user].present?
      smtp.expects(:start).with('localhost.localdomain', @chan.configuration[:user], @chan.configuration[:password])
    else
      smtp.expects(:start).with('localhost.localdomain')
    end
    smtp.expects(:send_message).with(msgstr, msg.from.without_protocol, msg.to.without_protocol)
    smtp.expects(:finish)
  end

  def deliver(msg)
    job = SendSmtpMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def expect_ao_message_was_delivered
    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

end
