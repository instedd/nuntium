require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PushQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  def test_perform_first_run
    account = setup_account
    msgs = new_at_message account, (0..2)
    setup_http account, 
      :msgs_posted => (0..2), 
      :post_etag => msgs[2].guid,
      :head_etag => nil
    
    result = job account
    
    assert_equal :success, result
    assert_last_id account, msgs[2].guid
    assert_msgs_states(msgs, 'confirmed', 1)
    
  end
  
  def test_perform_run_with_last_id
    account = setup_account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_complex_uri
    account = setup_account :url => 'http://example.com:9099/foobar/'
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_port => 9099,
      :url_host => 'example.com',
      :url_path => '/foobar/incoming'

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_complex_ssl_uri
    account = setup_account :url => 'https://geochat-stg.instedd.org/gateway/gateway.svc'
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_port => 443,
      :url_host => 'geochat-stg.instedd.org',
      :url_path => '/gateway/gateway.svc/incoming',
      :use_ssl => true

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_on_ssl
    account = setup_account :url => 'https://example.com'
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_host => 'example.com',
      :use_ssl => true,
      :url_port => 443

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  def test_perform_run_with_last_id_unauth
    account = setup_account_unauth 
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :auth => false

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  
  def test_perform_run_with_last_id_not_confirming_all_messages
    account = setup_account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued'
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[4].guid

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[4].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'delivered', 1)
  end

  def test_perform_run_with_last_id_after_partial_post
    account = setup_account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message account, (6..7), 'protocol', 'queued', 0
    account.set_last_at_guid msgs[2].guid
    
    setup_http account, :msgs_posted => (3..7), 
      :expects_head => false,
      :post_etag => msgs[7].guid
      
    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  
  def test_perform_run_requesting_last_id_after_failure
    account = setup_account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message account, (6..7), 'protocol', 'queued', 0
    account.set_last_at_guid nil
    
    setup_http account, :msgs_posted => (3..7), 
      :head_etag => msgs[2].guid,
      :post_etag => msgs[7].guid
      
    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  def test_perform_run_requesting_greater_last_id_after_failure
    account = setup_account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message account, (6..7), 'protocol', 'queued', 0
    account.set_last_at_guid nil
    
    setup_http account, :msgs_posted => (5..7), 
      :head_etag => msgs[4].guid,
      :post_etag => msgs[7].guid

    result = job account
        
    assert_equal :success, result
    assert_last_id account, msgs[7].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'confirmed', 2)
    assert_msgs_states(msgs[6..7], 'confirmed', 1)
  end
  
  def test_failed_post_clears_last_id_and_increases_tries
    account = setup_account :max_tries => 5
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'queued', 4
    msgs += new_at_message account, (6..7), 'protocol', 'queued', 0
    account.set_last_at_guid(msgs[2].guid)
    
    setup_http account, :msgs_posted => (3..7), 
      :expects_head => false, 
      :post_response => mock_http_failure

    result = job account
        
    assert_equal :failed, result
    assert_last_id account, nil
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'failed', 5
    assert_msgs_states msgs[6..7], 'queued', 1
  end
  
  def test_failed_when_no_url
    account = create_account_with_interface('myaccount', 'mypass', 'qst_client', {})
    msgs = sample_messages(account)
    setup_null_http account
    
    result = job account
    assert_equal :error_no_url_in_configuration, result
    assert_last_id account, nil
    assert_sample_messages_states msgs
  end
  
  def test_failed_when_wrong_interface
    account = create_account_with_interface('myaccount', 'mypass', 'rss', { :url => 'http://example.com' })
    msgs = sample_messages(account)
    setup_null_http account
    
    result = job account
    assert_equal :error_wrong_interface, result
    assert_last_id account, nil
    assert_sample_messages_states msgs
  end
  
  def test_failed_when_obtaining_last_guid
    account = setup_account
    msgs = sample_messages(account)
    setup_http account, 
      :expects_post => false,
      :head_response => mock_http_failure
    
    result = job account
    
    assert_equal :error_obtaining_last_id, result
    assert_last_id account, nil
    assert_sample_messages_states msgs
  end
  
  def test_batch_returns_success_pending
    account = setup_account :max_tries => 5
    msgs =  new_at_message account, (0..20), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (21..100), 'protocol', 'queued', 0
    account.set_last_at_guid(msgs[20].guid)
    
    setup_http account, :msgs_posted => (21..30), 
      :expects_head => false, 
      :post_etag => msgs[30].guid

    result = batch account
        
    assert_equal :success_pending, result
    assert_last_id account, msgs[30].guid
    assert_msgs_states msgs[0..30], 'confirmed', 1 
    assert_msgs_states msgs[31..100], 'queued', 0
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_full
    account = setup_account :max_tries => 5
    msgs =  new_at_message account, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (20...100), 'protocol', 'queued', 0
    account.set_last_at_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(account) do
      assert current < 101
      if current == 100
        setup_http account, 
          :expects_post => false, 
          :expects_head => false
      else
        setup_http account, 
          :msgs_posted => (current...current+10), 
          :expects_head => false, 
          :post_etag => msgs[current+9].guid
        current += 10
      end
    end
        
    assert_equal :success, result
    assert_last_id account, msgs[99].guid
    assert_msgs_states msgs[0...100], 'confirmed', 1 
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_partial
    account = setup_account :max_tries => 5
    msgs =  new_at_message account, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (20...105), 'protocol', 'queued', 0
    account.set_last_at_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(account) do
      max = if current == 100 then 104 else current + 9 end
      setup_http account, 
        :msgs_posted => (current..max), 
        :expects_head => false, 
        :post_etag => msgs[max].guid
      current = max + 1
    end
        
    assert_equal :success, result
    assert_last_id account, msgs[104].guid
    assert_msgs_states msgs[0...105], 'confirmed', 1 
  end
  
  def test_perform_runs_until_quota_exceeded
    account = setup_account :max_tries => 5
    msgs =  new_at_message account, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (20...100), 'protocol', 'queued', 0
    account.set_last_at_guid(msgs[19].guid)
    
    set_current_time
    
    current = 20
    lapse = 0
    
    job = create_job_with_callback(account) do
      assert current < 101
      if current == 50
        setup_http account,
          :expects_post => false, 
          :expects_head => false
      else
        setup_http account, 
          :msgs_posted => (current...current+10), 
          :expects_head => false, 
          :post_etag => msgs[current+9].guid
        
        current += 10
        lapse += 10
        
        set_current_time(base_time + lapse)
      end
    end
    
    job.quota = 25
    
    assert_equal :success_pending, job.perform
    assert_last_id account, msgs[49].guid
    assert_msgs_states msgs[0...50], 'confirmed', 1 
    assert_msgs_states msgs[50...100], 'queued', 0
    
  end
  
  private
  
  def assert_last_id(account, last_id)
    afteraccount = Account.find_by_id account.id
    assert_equal last_id, afteraccount.configuration[:last_at_guid]
  end
  
  def setup_account(cfg = {})
    create_account_with_interface('account', 'pass', 'qst_client', { :last_at_guid => nil, :url => 'http://example.com', :cred_user => 'theuser', :cred_pass => 'thepass' }.merge(cfg))
  end
  
  def setup_account_unauth(cfg = {})
    create_account_with_interface('account', 'pass', 'qst_client', { :last_at_guid => nil, :url => 'http://example.com'}.merge(cfg))
  end
  
  def setup_null_http(account)
    setup_http account, :auth => false, 
      :expects_head => false,
      :expects_post => false,
      :expects_init => false
  end
  
  def setup_http(account, opts)
    cfg = { 
      :auth => true, 
      :expects_head => true,  
      :expects_post => true,  
      :expects_init => true,
      :msgs_posted => (0..0),
      :url_host => 'example.com',
      :url_port => 80,
      :url_path => 'incoming',
      :use_ssl => false
    }.merge(opts)
    
    cfg[:head_response] = mock_http_success('etag' => cfg[:head_etag]) if cfg[:head_response].nil?
    cfg[:post_response] = mock_http_success('etag' => cfg[:post_etag]) if cfg[:post_response].nil?
    
    user = cfg[:auth] ? 'theuser' : nil
    pass = cfg[:auth] ? 'thepass' : nil
    
    http = mock_http(cfg[:url_host], cfg[:url_port], cfg[:expects_init], cfg[:use_ssl])
    reqs = states('reqs')
    
    if cfg[:expects_head] and cfg[:expects_init]
      head = mock_http_request(Net::HTTP::Head, cfg[:url_path], 'head', user, pass) 
      http.expects(:request).with(head).returns(cfg[:head_response]).then(reqs.is('has_last_id'))
    else
      reqs.become('has_last_id')
    end
    
    if cfg[:expects_post] and cfg[:expects_init]
      post = mock_http_request(Net::HTTP::Post, cfg[:url_path], 'post', user, pass, { 'Content-Type' => 'text/xml' })
      http.expects(:request).with(post, anything).returns(cfg[:post_response]).when(reqs.is('has_last_id'))
      # TODO: Must assert messages using custom parameter matcher (with block fails because of previous head invocation)
    end

    http
  end
  
  def sample_messages account
    msgs =  new_at_message account, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message account, (3..5), 'protocol', 'delivered', 3
    msgs += new_at_message account, (6..7), 'protocol', 'failed', 5
    msgs += new_at_message account, (8..10), 'protocol', 'queued', 0
    msgs
  end
  
  def assert_sample_messages_states msgs
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'delivered', 3
    assert_msgs_states msgs[6..7], 'failed', 5
    assert_msgs_states msgs[8..10], 'queued', 0
  end
  
  class CallbackJob < PushQstMessageJob
    def initialize(account_id, block)
      super account_id
      @block = block
    end
    def perform_batch
      @block.call
      super
    end
  end
  
  def create_job_with_callback(account, &block)
    CallbackJob.new account.id, block
  end
  
  def job_with_callback(account, &block)
    j = CallbackJob.new account.id, block
    j.perform
  end
  
  def job(account)
    j = PushQstMessageJob.new account.id
    j.perform
  end
  
  def batch(account)
    j = PushQstMessageJob.new account.id
    j.perform_batch
  end
  
end
