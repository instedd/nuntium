require 'test_helper'
require 'net/smtp'

class SendSmtpMessageJobTest < ActiveSupport::TestCase
  def setup
    @time = Time.now
    @chan = Channel.make :smtp
  end

  should "perform no ssl" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan
    msgstr = msg_as_email msg    
    expect_smtp msg, msgstr
    assert_true (deliver msg)
    expect_ao_message_was_delivered
  end
  
  should "perform ssl" do
    @chan.configuration[:use_ssl] = '1'
    @chan.save!
    
    msg = AOMessage.make :account => @chan.account, :channel => @chan
    msgstr = msg_as_email msg
    expect_smtp msg, msgstr
    assert_true (deliver msg)
    expect_ao_message_was_delivered
  end
  
  should "perform with thread" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan
    msg.custom_attributes['references_thread'] = 'foo'
    msg.save!
    
    msgstr = msg_as_email msg    
    expect_smtp msg, msgstr
    assert_true (deliver msg)
    expect_ao_message_was_delivered
  end
  
  should "perform with references" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan
    msg.custom_attributes['references_foo'] = 'a'
    msg.custom_attributes['references_bar'] = 'b'
    msg.save!
    
    msgstr = msg_as_email msg    
    expect_smtp msg, msgstr
    assert_true (deliver msg)
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
    smtp.expects(:start).with('localhost.localdomain', @chan.configuration[:user], @chan.configuration[:password])
    smtp.expects(:send_message).with(msgstr, msg.from.without_protocol, msg.to.without_protocol)
    smtp.expects(:finish)
  end
  
  def deliver(msg)
    job = SendSmtpMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end
  
  def expect_ao_message_was_delivered
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
end
