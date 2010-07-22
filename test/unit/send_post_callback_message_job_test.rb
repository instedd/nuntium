require 'test_helper'

class SendPostCallbackMessageJobTest < ActiveSupport::TestCase
  def setup
    @application = Application.make
    @chan = Channel.make :account => @application.account, :application => @application
    @msg = ATMessage.make :account => @application.account, :application => @application, :channel => @chan
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
  
  test "post" do
    @application.interface_url = 'http://www.domain.com'
    @application.save!
    
    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end
  
  test "post with auth" do
    @application.interface_url = 'http://www.domain.com'
    @application.interface_user = 'john'
    @application.interface_password = 'pass'
    @application.save!
    
    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}, :user => @application.interface_user, :password => @application.interface_password},
      :returns => Net::HTTPSuccess
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end
  
  test "post unauthorized" do
    @application.interface_url = 'http://www.domain.com'
    @application.save!
    
    expect_post :url => @application.interface_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPUnauthorized
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
    
    @application.reload
    assert_equal 'rss', @application.interface
  end
  
  test "discard not queued messages" do
    expect_no_rest
    
    @msg.state = 'cancelled'
    @msg.save!
    
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    assert_true job.perform
  end
end
