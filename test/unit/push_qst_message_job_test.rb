require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PushQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  def test_perform_first_run
    application = setup_application
    msgs = new_at_message application, (0..2)
    setup_http application, 
      :msgs_posted => (0..2), 
      :post_etag => msgs[2].guid,
      :head_etag => nil
    
    result = job application
    
    assert_equal :success, result
    assert_last_id application, msgs[2].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id
    application = setup_application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_complex_uri
    application = setup_application :interface_url => 'http://example.com:9099/foobar/'
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_port => 9099,
      :url_host => 'example.com',
      :url_path => '/foobar/incoming'

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_complex_ssl_uri
    application = setup_application :interface_url => 'https://geochat-stg.instedd.org/gateway/gateway.svc'
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_port => 443,
      :url_host => 'geochat-stg.instedd.org',
      :url_path => '/gateway/gateway.svc/incoming',
      :use_ssl => true

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_last_id_on_ssl
    application = setup_application :interface_url => 'https://example.com'
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_host => 'example.com',
      :use_ssl => true,
      :url_port => 443

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  def test_perform_run_with_last_id_unauth
    application = setup_application_unauth 
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :auth => false

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  
  def test_perform_run_with_last_id_not_confirming_all_messages
    application = setup_application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued'
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[4].guid

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[4].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'delivered', 1)
  end

  def test_perform_run_with_last_id_after_partial_post
    application = setup_application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message application, (6..7), 'protocol', 'queued', 0
    application.set_last_at_guid msgs[2].guid
    
    setup_http application, :msgs_posted => (3..7), 
      :expects_head => false,
      :post_etag => msgs[7].guid
      
    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  
  def test_perform_run_requesting_last_id_after_failure
    application = setup_application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message application, (6..7), 'protocol', 'queued', 0
    application.set_last_at_guid nil
    
    setup_http application, :msgs_posted => (3..7), 
      :head_etag => msgs[2].guid,
      :post_etag => msgs[7].guid
      
    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  def test_perform_run_requesting_greater_last_id_after_failure
    application = setup_application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message application, (6..7), 'protocol', 'queued', 0
    application.set_last_at_guid nil
    
    setup_http application, :msgs_posted => (5..7), 
      :head_etag => msgs[4].guid,
      :post_etag => msgs[7].guid

    result = job application
        
    assert_equal :success, result
    assert_last_id application, msgs[7].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'confirmed', 2)
    assert_msgs_states(msgs[6..7], 'confirmed', 1)
  end
  
  def test_failed_post_clears_last_id_and_increases_tries
    application = setup_application :max_tries => 5
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'queued', 4
    msgs += new_at_message application, (6..7), 'protocol', 'queued', 0
    application.set_last_at_guid(msgs[2].guid)
    
    setup_http application, :msgs_posted => (3..7), 
      :expects_head => false, 
      :post_response => mock_http_failure

    result = job application
        
    assert_equal :failed, result
    assert_last_id application, nil
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'failed', 5
    assert_msgs_states msgs[6..7], 'queued', 1
  end
  
  def test_failed_when_obtaining_last_guid
    application = setup_application
    msgs = sample_messages(application)
    setup_http application,
      :expects_post => false,
      :head_response => mock_http_failure
    
    result = job application
    
    assert_equal :error_obtaining_last_id, result
    assert_last_id application, nil
    assert_sample_messages_states msgs
  end
  
  def test_batch_returns_success_pending
    application = setup_application :max_tries => 5
    
    msgs =  new_at_message application, (0..20), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (21..100), 'protocol', 'queued', 0
    application.set_last_at_guid(msgs[20].guid)
    
    setup_http application, :msgs_posted => (21..30), 
      :expects_head => false, 
      :post_etag => msgs[30].guid

    result = batch application
        
    assert_equal :success_pending, result
    assert_last_id application, msgs[30].guid
    assert_msgs_states msgs[0..30], 'confirmed', 1 
    assert_msgs_states msgs[31..100], 'queued', 0
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_full
    application = setup_application :max_tries => 5
    msgs =  new_at_message application, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (20...100), 'protocol', 'queued', 0
    application.set_last_at_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(application) do
      assert current < 101
      if current == 100
        setup_http application, 
          :expects_post => false, 
          :expects_head => false
      else
        setup_http application, 
          :msgs_posted => (current...current+10), 
          :expects_head => false, 
          :post_etag => msgs[current+9].guid
        current += 10
      end
    end
        
    assert_equal :success, result
    assert_last_id application, msgs[99].guid
    assert_msgs_states msgs[0...100], 'confirmed', 1 
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_partial
    application = setup_application :max_tries => 5
    msgs =  new_at_message application, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (20...105), 'protocol', 'queued', 0
    application.set_last_at_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(application) do
      max = if current == 100 then 104 else current + 9 end
      setup_http application, 
        :msgs_posted => (current..max), 
        :expects_head => false, 
        :post_etag => msgs[max].guid
      current = max + 1
    end
        
    assert_equal :success, result
    assert_last_id application, msgs[104].guid
    assert_msgs_states msgs[0...105], 'confirmed', 1 
  end
  
  def test_perform_runs_until_quota_exceeded
    application = setup_application :max_tries => 5
    msgs =  new_at_message application, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (20...100), 'protocol', 'queued', 0
    application.set_last_at_guid(msgs[19].guid)
    
    set_current_time
    
    current = 20
    lapse = 0
    
    job = create_job_with_callback(application) do
      assert current < 101
      if current == 50
        setup_http application,
          :expects_post => false, 
          :expects_head => false
      else
        setup_http application, 
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
    assert_last_id application, msgs[49].guid
    assert_msgs_states msgs[0...50], 'confirmed', 1 
    assert_msgs_states msgs[50...100], 'queued', 0
    
  end
  
  private
  
  def assert_last_id(application, last_id)
    afterapplication = Application.find_by_id application.id
    assert_equal last_id, afterapplication.configuration[:last_at_guid]
  end
  
  def setup_application(cfg = {})
    Application.make :qst_client, :configuration => { 
      :last_ao_guid => nil, 
      :interface_url => 'http://example.com', 
      :interface_user => 'theuser', 
      :interface_password => 'thepass' }.merge(cfg)
  end
  
  def setup_application_unauth(cfg = {})
    Application.make :qst_client, :configuration => { 
      :last_ao_guid => nil, 
      :interface_url => 'http://example.com' }.merge(cfg)
  end
  
  def setup_null_http(application)
    setup_http application, :auth => false, 
      :expects_head => false,
      :expects_post => false,
      :expects_init => false
  end
  
  def setup_http(application, opts)
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
  
  def sample_messages application
    msgs =  new_at_message application, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message application, (3..5), 'protocol', 'delivered', 3
    msgs += new_at_message application, (6..7), 'protocol', 'failed', 5
    msgs += new_at_message application, (8..10), 'protocol', 'queued', 0
    msgs
  end
  
  def assert_sample_messages_states msgs
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'delivered', 3
    assert_msgs_states msgs[6..7], 'failed', 5
    assert_msgs_states msgs[8..10], 'queued', 0
  end
  
  class CallbackJob < PushQstMessageJob
    def initialize(application_id, block)
      super application_id
      @block = block
    end
    def perform_batch
      @block.call
      super
    end
  end
  
  def create_job_with_callback(application, &block)
    CallbackJob.new application.id, block
  end
  
  def job_with_callback(application, &block)
    j = CallbackJob.new application.id, block
    j.perform
  end
  
  def job(application)
    j = PushQstMessageJob.new application.id
    j.perform
  end
  
  def batch(application)
    j = PushQstMessageJob.new application.id
    j.perform_batch
  end
  
  # Given a list of message or ids, checks that each message in the db has the specified state and tries
  def assert_msgs_states(msg_ids, state, tries, kind=ATMessage)
    msg_ids.each { |msg| assert_msg_state msg, state, tries, kind }
  end
  
  # Given a message id, checks that message in the db has the specified state and tries
  def assert_msg_state(msg_or_id, state, tries,kind=ATMessage)
    msg_id = msg_or_id.id unless msg_or_id.kind_of? String
    msg = kind.find_by_id(msg_id)
    assert_not_nil msg, "message with id #{msg_id} not found"
    assert_equal state, msg.state, "message with id #{msg_id} state does not match"
    assert_equal tries, msg.tries, "message with id #{msg_id} tries does not match"
  end
  
end
