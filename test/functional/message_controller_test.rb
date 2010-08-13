require 'test_helper'

class MessageControllerTest < ActionController::TestCase

  def setup
    @account = Account.make
    @application = Application.make :account => @account
    Channel.make :account => @account
    
    @ao_msg1 = AOMessage.create!(:account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1')
    @ao_msg2 = AOMessage.create!(:account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1')
    @ao_msg3 = AOMessage.create!(:account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'two', :to => 'sms://1', :tries => 3)
    
    @at_msg1 = ATMessage.create!(:account_id => @account.id, :state => 'queued', :body => 'one')
    @at_msg2 = ATMessage.create!(:account_id => @account.id, :state => 'queued', :body => 'one')
    @at_msg3 = ATMessage.create!(:account_id => @account.id, :state => 'queued', :body => 'two')
  end
  
  def assert_fields(kind, member, *states)
    msgs = (kind == :ao ? AOMessage : ATMessage).all
    assert_equal states.length, msgs.length
    states.length.times do |i|
      assert_equal states[i], msgs[i].send(member)
    end
  end

  test "mark ao messages as cancelled" do
    get :mark_ao_messages_as_cancelled, {:ao_messages => [@ao_msg1.id, @ao_msg2.id]}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :ao_messages => [@ao_msg1.id, @ao_msg2.id])
    assert_equal '2 Application Originated messages were marked as cancelled', flash[:notice]
    
    assert_fields :ao, :state, 'cancelled', 'cancelled', 'pending'
  end
  
  test "mark ao messages as cancelled using search" do
    get :mark_ao_messages_as_cancelled, {:ao_all => 1, :ao_search => 'one'}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :ao_all => 1, :ao_search => 'one')
    assert_equal '2 Application Originated messages were marked as cancelled', flash[:notice]
    
    assert_fields :ao, :state, 'cancelled', 'cancelled', 'pending'
  end
  
  test "mark at messages as cancelled" do
    get :mark_at_messages_as_cancelled, {:at_messages => [@at_msg1.id, @at_msg2.id]}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :at_messages => [@at_msg1.id, @at_msg2.id])
    assert_equal '2 Application Terminated messages were marked as cancelled', flash[:notice]
    
    assert_fields :at, :state, 'cancelled', 'cancelled', 'queued'
  end
  
  test "mark at messages as cancelled using search" do
    get :mark_at_messages_as_cancelled, {:at_all => 1, :at_search => 'one'}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :at_all => 1, :at_search => 'one')
    assert_equal '2 Application Terminated messages were marked as cancelled', flash[:notice]
    
    assert_fields :at, :state, 'cancelled', 'cancelled', 'queued'
  end
  
  test "re-route ao messages" do
    get :reroute_ao_messages, {:ao_messages => [@ao_msg1.id, @ao_msg2.id]}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :ao_messages => [@ao_msg1.id, @ao_msg2.id])
    assert_equal '2 Application Originated messages were re-routed', flash[:notice]
    
    assert_fields :ao, :state, 'queued', 'queued', 'pending'
    assert_fields :ao, :tries, 0, 0, 3
  end
  
  test "re-route ao messages using search" do
    get :reroute_ao_messages, {:ao_all => 1, :ao_search => 'one'}, {:account_id => @account.id}
    
    assert_redirected_to(:controller => 'home', :action => 'index', :ao_all => 1, :ao_search => 'one')
    assert_equal '2 Application Originated messages were re-routed', flash[:notice]
    
    assert_fields :ao, :state, 'queued', 'queued', 'pending'
    assert_fields :ao, :tries, 0, 0, 3
  end

end
