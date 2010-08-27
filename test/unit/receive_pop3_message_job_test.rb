require 'test_helper'
require 'net/pop'
require 'yaml'

class ReceivePop3MessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :pop3
    @email = ATMessage.make_unsaved :email
  end

  should "perform no ssl" do
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
    
    expect_connection @chan, mail
    
    receive
    expect_at_message
  end
  
  should "perform ssl" do
    @chan.configuration[:use_ssl] = '1'
    @chan.save!
      
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
    
    expect_connection @chan, mail
    
    receive
    expect_at_message
  end
  
  should "perform no message id" do
    @email.guid = nil
  
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
      
    expect_connection @chan, mail
    
    receive
    expect_at_message
  end
  
  should "perform no ssl removing quoted text" do
    @chan.configuration[:remove_quoted_text_or_text_after_first_empty_line] = '1'
    @chan.save!
    
    @email.body = "Hello\n\nGoodbye"
  
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
    
    expect_connection @chan, mail
    
    receive
    expect_at_message :body => "Hello"
  end
  
  should "perform set thread" do
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email, :references => '<a@foo.bar>, <b@nuntium>, <c@nuntium-thread>')
    
    expect_connection @chan, mail
    
    receive
    expect_at_message :reply_to => 'b', :thread => 'c'
  end
  
  should "remove quoted text or text after first empty line, case quoted text" do
    original = "Hello\n>One\n>Two\n>Three"
    result = ReceivePop3MessageJob.remove_quoted_text_or_text_after_first_empty_line original
    assert_equal "Hello", result
  end
  
  should "remove quoted text or text after first empty line, case On...:" do
    original = "Hello\n\nOn some date someone wrote:\n>One\n>Two\n>Three"
    result = ReceivePop3MessageJob.remove_quoted_text_or_text_after_first_empty_line original
    assert_equal "Hello", result
  end
  
  should "remove quoted text or text after first empty line, case empty line:" do
    original = "Hello\n\nGoodbye"
    result = ReceivePop3MessageJob.remove_quoted_text_or_text_after_first_empty_line original
    assert_equal "Hello", result
  end
  
  should "not throw if mail has no to field" do
    @email.to = nil
  
    AccountLogger.expects(:exception_in_channel).never
    
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
    
    expect_connection @chan, mail
    receive
    
    assert_equal 1, ATMessage.count
  end
  
  should "not throw if mail has no from field" do
    @email.from = nil
  
    AccountLogger.expects(:exception_in_channel).never
    
    mail = mock('Net::POPMail')
    mail.stubs :pop => msg_as_email(@email)
    
    expect_connection @chan, mail
    receive
    
    assert_equal 1, ATMessage.count
  end
  
  def msg_as_email(email, options = {})
    msg = ""
    msg << "From: #{email.from.without_protocol}\n" if email.from
    msg << "To: #{email.to.without_protocol}\n" if email.to
    msg << "Subject: #{email.subject}\n"
    msg << "Date: Thu, 5 Nov 2009 14:52:54 +0100\n"
    msg << "Message-ID: <#{email.guid}@baci.local.tmail>\n" unless email.guid.blank?
    msg << "References: #{options[:references]}\n" if options[:references]
    msg << "\n"
    msg << email.body
    msg
  end
  
  def expect_connection(chan, mail)
    pop = mock('Net::Pop3')
    Net::POP3.expects(:new).with(chan.configuration[:host], chan.configuration[:port]).returns(pop)
    pop.expects(:enable_ssl).with(OpenSSL::SSL::VERIFY_NONE) if chan.configuration[:use_ssl].to_b
    pop.expects(:start).with(chan.configuration[:user], chan.configuration[:password])
    pop.expects(:each_mail).yields(mail)
    mail.expects(:delete)
    pop.expects(:finish)
  end
  
  def receive
    job = ReceivePop3MessageJob.new(@chan.account.id, @chan.id)
    job.perform
  end
  
  def expect_at_message(options = {})
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal @chan.account.id, msg.account_id
    [:from, :to, :subject, :body].each do |field|
      assert_equal (options[field] || @email.send(field).strip), msg.send(field).strip
    end
    assert_equal "<#{@email.guid}@baci.local.tmail>", msg.channel_relative_id if @email.guid.present?
    assert_equal options[:reply_to], msg.custom_attributes['reply_to'] if options[:reply_to]
    assert_equal options[:thread], msg.custom_attributes['thread'] if options[:thread]
    
    assert_not_nil msg.guid
    assert_equal Time.parse('Thu, 5 Nov 2009 14:52:54 +0100'), msg.timestamp
  end
end
