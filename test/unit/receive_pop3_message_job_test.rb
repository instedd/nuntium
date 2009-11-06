require 'test_helper'
require 'net/pop'
require 'mocha'

class ReceivePop3MessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  should "perform no ssl" do
    app = Application.create(:name => 'app', :password => 'pass')
    chan = Channel.create(:application_id => app.id, :name => 'chan', :protocol => 'protocol', :kind => 'pop3', 
      :configuration => {:host => 'the_host', :port => 123, :user => 'the_user', :password => 'the_password', :use_ssl => '0'})
      
    mail = mock('Net::POPMail')
    mail.stubs(
      :pop =>
<<-END_OF_MESSAGE
From: from@mail.com
To: to@mail.com
Subject: some subject
Date: Thu, 5 Nov 2009 14:52:54 +0100

Hello!
END_OF_MESSAGE
    )
      
    pop = mock('Net::Pop3')
    Net::POP3.expects(:new).with('the_host', 123).returns(pop)
    pop.expects(:start).with('the_user', 'the_password')
    pop.expects(:each_mail).yields(mail)
    mail.expects(:delete)
    pop.expects(:finish)
      
    job = ReceivePop3MessageJob.new(app.id, chan.id)
    job.perform
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal app.id, msg.application_id
    assert_equal 'mailto://from@mail.com', msg.from
    assert_equal 'mailto://to@mail.com', msg.to
    assert_equal 'some subject', msg.subject
    assert_equal "Hello!\n", msg.body
    assert_equal Time.parse('Thu, 5 Nov 2009 14:52:54 +0100'), msg.timestamp
  end
end