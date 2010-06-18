require 'test_helper'
require 'mq'

class XmppChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :xmpp
  end
  
  [:user, :domain, :password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should enqueue when handling" do
    assert_handler_should_enqueue_ao_job @chan, SendXmppMessageJob
  end
  
  test "on enable creates managed process" do
    @chan.save!
    
    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_equal @chan.account.id, proc.account_id
    assert_equal "xmpp_daemon #{@chan.name}", proc.name
    assert_equal "xmpp_daemon_ctl.rb start -- test #{@chan.id}", proc.start_command
    assert_equal "xmpp_daemon_ctl.rb stop -- test #{@chan.id}", proc.stop_command
    assert_equal "xmpp_daemon.#{@chan.id}.pid", proc.pid_file
    assert_equal "xmpp_daemon_#{@chan.id}.log", proc.log_file
  end
  
  test "on enable binds queue" do
    chan = Channel.make_unsaved :smpp
    Queues.expects(:bind_ao).with(chan)  
    chan.save!
  end
  
  test "on destroy deletes managed process" do
    @chan.destroy    
    assert_equal 0, ManagedProcess.count
  end
  
  test "on change touches managed process" do
    proc = mock('ManagedProcess')
  
    ManagedProcess.expects(:find_by_account_id_and_name).
      with(@chan.account.id, "xmpp_daemon #{@chan.name}").
      returns(proc)
    proc.expects(:touch)
    
    @chan.touch
  end
  
end
