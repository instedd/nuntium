require 'test_helper'

class SendDeliveryAckJobTest < ActiveSupport::TestCase
  def setup
    @application = Application.make
    @chan = Channel.make :account => @application.account, :application => @application
    @msg = AOMessage.make :account => @application.account, :application => @application, :channel => @chan
    @query = {:guid => @msg.guid, :channel => @chan.name, :state => @msg.state}
  end

  test "get" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('get').with("http://www.domain.com?#{@query.to_query}", :content_type => "application/x-www-form-urlencoded").returns(response)
  
    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end
  
  test "get with auth" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.delivery_ack_user = 'john'
    @application.delivery_ack_password = 'doe'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('get').with("http://www.domain.com?#{@query.to_query}", :content_type => "application/x-www-form-urlencoded", :user => @application.delivery_ack_user, :password => @application.delivery_ack_password).returns(response)
  
    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end
  
  test "post" do
    @application.delivery_ack_method = 'post'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('post').with("http://www.domain.com", @query, :content_type => "application/x-www-form-urlencoded").returns(response)
  
    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end
  
  test "post with auth" do
    @application.delivery_ack_method = 'post'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.delivery_ack_user = 'john'
    @application.delivery_ack_password = 'doe'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPSuccess.new 'x', 'x', 'x')
    
    RestClient.expects('post').with("http://www.domain.com", @query, :content_type => "application/x-www-form-urlencoded", :user => @application.delivery_ack_user, :password => @application.delivery_ack_password).returns(response)
  
    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end
  
  test "get unauthorized" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!
  
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(Net::HTTPUnauthorized.new 'x', 'x', 'x')
    
    RestClient.expects('get').with("http://www.domain.com?#{@query.to_query}", :content_type => "application/x-www-form-urlencoded").returns(response)
  
    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
    
    @application.reload
    assert_equal 'none', @application.delivery_ack_method
  end

end
