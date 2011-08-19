require 'test_helper'

class SendDeliveryAckJobTest < ActiveSupport::TestCase
  def setup
    @application = Application.make
    @chan = Channel.make :account => @application.account, :application => @application
    @msg = AoMessage.make :account => @application.account, :application => @application, :channel => @chan
    @query = {:guid => @msg.guid, :channel => @chan.name, :state => @msg.state}
  end

  test "get" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!

    expect_get :url => @application.delivery_ack_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end

  test "get with auth" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.delivery_ack_user = 'john'
    @application.delivery_ack_password = 'doe'
    @application.save!

    expect_get :url => @application.delivery_ack_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}, :user => @application.delivery_ack_user, :password => @application.delivery_ack_password},
      :returns => Net::HTTPSuccess

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end

  test "get with custom attributes" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!

    @msg.custom_attributes['foo'] = 'bar'
    @msg.save!

    expect_get :url => @application.delivery_ack_url,
      :query_params => @query.merge(@msg.custom_attributes),
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end

  test "post" do
    @application.delivery_ack_method = 'post'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!

    expect_post :url => @application.delivery_ack_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end

  test "post with auth" do
    @application.delivery_ack_method = 'post'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.delivery_ack_user = 'john'
    @application.delivery_ack_password = 'doe'
    @application.save!

    expect_post :url => @application.delivery_ack_url,
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}, :user => @application.delivery_ack_user, :password => @application.delivery_ack_password},
      :returns => Net::HTTPSuccess

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform
  end

  test "get unauthorized" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!

    expect_get :url => @application.delivery_ack_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPUnauthorized

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    begin
      job.perform
    rescue => ex
      exception = ex
    else
      fail "Expected exception to be thrown"
    end

    job.reschedule exception

    sjobs = ScheduledJob.all
    assert_equal 1, sjobs.length

    republish = sjobs.first.job.deserialize_job
    assert_true republish.kind_of?(RepublishApplicationJob)
    assert_equal @application.id, republish.application_id

    job = republish.job
    assert_true job.kind_of?(SendDeliveryAckJob)
    assert_equal @application.account_id, job.account_id
    assert_equal @application.id, job.application_id
    assert_equal @msg.id, job.message_id
    assert_equal @msg.state, job.state
    assert_equal 1, job.tries

    @application.reload
    assert_equal 'get', @application.delivery_ack_method
  end

  test "get bad request" do
    @application.delivery_ack_method = 'get'
    @application.delivery_ack_url = 'http://www.domain.com'
    @application.save!

    expect_get :url => @application.delivery_ack_url,
      :query_params => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPBadRequest

    job = SendDeliveryAckJob.new @application.account_id, @application.id, @msg.id, @msg.state
    job.perform

    @application.reload
    assert_equal 'get', @application.delivery_ack_method

    logs = Log.all
    assert_equal 1, logs.length
    assert_equal "Received HTTP Bad Request (404) for delivery ack", logs[0].message
    assert_equal @msg.id, logs[0].ao_message_id
  end

end
