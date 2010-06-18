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
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('post').with(@application.interface_url, @query, :content_type => "application/x-www-form-urlencoded").returns(response)
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end
  
  test "post with auth" do
    @application.interface_url = 'http://www.domain.com'
    @application.interface_user = 'john'
    @application.interface_password = 'pass'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('post').with(@application.interface_url, @query, :content_type => "application/x-www-form-urlencoded", :user => @application.interface_user, :password => @application.interface_password).returns(response)
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
  end
  
  test "post unauthorized" do
    @application.interface_url = 'http://www.domain.com'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPUnauthorized.new 'x', 'x', 'x')
    
    RestClient.expects('post').with(@application.interface_url, @query, :content_type => "application/x-www-form-urlencoded").returns(response)
  
    job = SendPostCallbackMessageJob.new @application.account_id, @application.id, @msg.id
    job.perform
    
    @application.reload
    assert_equal 'rss', @application.interface
  end
end
