require 'test_helper'
require 'net/smtp'
require 'mocha'

class SendSmtpMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  should "perform no ssl" do
    time = Time.now
    
    account = Account.create(:name => 'account', :password => 'pass')
    chan = Channel.new(:account_id => account.id, :name => 'chan', :protocol => 'protocol', :kind => 'smtp')
    chan.configuration = {:host => 'the_host', :port => 123, :user => 'the_user', :password => 'the_password', :use_ssl => '0'}
    chan.save
    
    msg = AOMessage.create(:account_id => account.id, :from => 'mailto://from@mail.com', :to => 'mailto://to@mail.com', :subject => 'some subject', :body => 'some body', :timestamp => time, :guid => 'some guid', :state => 'pending')

msgstr = <<-END_OF_MESSAGE
From: from@mail.com
To: to@mail.com
Subject: some subject
Date: #{msg.timestamp}
Message-Id: <some guid@nuntium.instedd.org>

some body
END_OF_MESSAGE
msgstr.strip!
  
    smtp = mock('Net::SMTP')
  
    Net::SMTP.expects(:new).with('the_host', 123).returns(smtp)
    smtp.expects(:start).with('localhost.localdomain', 'the_user', 'the_password')
    smtp.expects(:send_message).with(msgstr, 'from@mail.com', 'to@mail.com')
    smtp.expects(:finish)
    
    job = SendSmtpMessageJob.new(account.id, chan.id, msg.id)
    job.perform
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
  should "perform ssl" do
    time = Time.now
    
    account = Account.create(:name => 'account', :password => 'pass')
    chan = Channel.new(:account_id => account.id, :name => 'chan', :protocol => 'protocol', :kind => 'smtp')
    chan.configuration = {:host => 'the_host', :port => 123, :user => 'the_user', :password => 'the_password', :use_ssl => '1'}
    chan.save
    
    msg = AOMessage.create(:account_id => account.id, :from => 'mailto://from@mail.com', :to => 'mailto://to@mail.com', :subject => 'some subject', :body => 'some body', :timestamp => time, :guid => 'some guid', :state => 'pending')

msgstr = <<-END_OF_MESSAGE
From: from@mail.com
To: to@mail.com
Subject: some subject
Date: #{msg.timestamp}
Message-Id: <some guid@nuntium.instedd.org>

some body
END_OF_MESSAGE
msgstr.strip!
  
    smtp = mock('Net::SMTP')
  
    Net::SMTP.expects(:new).with('the_host', 123).returns(smtp)
    smtp.expects(:enable_tls)
    smtp.expects(:start).with('localhost.localdomain', 'the_user', 'the_password')
    smtp.expects(:send_message).with(msgstr, 'from@mail.com', 'to@mail.com')
    smtp.expects(:finish)
    
    job = SendSmtpMessageJob.new(account.id, chan.id, msg.id)
    job.perform
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
end
