require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PushQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  @separate_msg_times_by_year = false
  
  def test_perform_first_run
    app = setup_app
    msgs = new_at_message app, (0..2)
    setup_http app, 
      :msgs_posted => (0..2), 
      :post_etag => msgs[2].guid,
      :head_etag => nil
    
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[2].guid
    assert_msgs_states(msgs, 'confirmed', 1)
    
  end
  
  def test_perform_run_with_last_id
    app = setup_app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'queued'
    app.set_last_guid(msgs[2].guid)
    
    setup_http app, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid

    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end
  
  def test_perform_run_with_complex_uri
    app = setup_app :url => 'http://example.com:9099/foobar/'
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'queued'
    app.set_last_guid(msgs[2].guid)
    
    setup_http app, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :url_port => 9099,
      :url_host => 'example.com',
      :url_path => '/foobar/incoming'

    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  def test_perform_run_with_last_id_unauth
    app = setup_app_unauth 
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'queued'
    app.set_last_guid(msgs[2].guid)
    
    setup_http app, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[5].guid,
      :auth => false

    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[5].guid
    assert_msgs_states(msgs, 'confirmed', 1)
  end

  
  def test_perform_run_with_last_id_not_confirming_all_messages
    app = setup_app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'queued'
    app.set_last_guid(msgs[2].guid)
    
    setup_http app, :msgs_posted => (3..5), 
      :expects_head => false, 
      :post_etag => msgs[4].guid

    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[4].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'delivered', 1)
  end

  def test_perform_run_with_last_id_after_partial_post
    app = setup_app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message app, (6..7), 'protocol', 'queued', 0
    app.set_last_guid msgs[2].guid
    
    setup_http app, :msgs_posted => (3..7), 
      :expects_head => false,
      :post_etag => msgs[7].guid
      
    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  
  def test_perform_run_requesting_last_id_after_failure
    app = setup_app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message app, (6..7), 'protocol', 'queued', 0
    app.set_last_guid nil
    
    setup_http app, :msgs_posted => (3..7), 
      :head_etag => msgs[2].guid,
      :post_etag => msgs[7].guid
      
    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[7].guid
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
    assert_msgs_states(msgs[3..5], 'confirmed', 2)
    assert_msgs_states(msgs[0..2], 'confirmed', 1)
  end

  def test_perform_run_requesting_greater_last_id_after_failure
    app = setup_app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'delivered', 1
    msgs += new_at_message app, (6..7), 'protocol', 'queued', 0
    app.set_last_guid nil
    
    setup_http app, :msgs_posted => (5..7), 
      :head_etag => msgs[4].guid,
      :post_etag => msgs[7].guid

    result = job app
        
    assert_equal :success, result
    assert_last_id app, msgs[7].guid
    assert_msgs_states(msgs[0..4], 'confirmed', 1)
    assert_msgs_states(msgs[5..5], 'confirmed', 2)
    assert_msgs_states(msgs[6..7], 'confirmed', 1)
  end
  
  def test_failed_post_clears_last_id_and_increases_tries
    app = setup_app :max_tries => 5
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'queued', 4
    msgs += new_at_message app, (6..7), 'protocol', 'queued', 0
    app.set_last_guid(msgs[2].guid)
    
    setup_http app, :msgs_posted => (3..7), 
      :expects_head => false, 
      :post_response => mock_http_failure

    result = job app
        
    assert_equal :failed, result
    assert_last_id app, nil
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'failed', 5
    assert_msgs_states msgs[6..7], 'queued', 1
  end
  
  def test_failed_when_no_url
    app = create_app_with_interface('myapp', 'mypass', 'qst', {})
    msgs = sample_messages(app)
    setup_null_http app
    
    result = job app
    assert_equal :error_no_url_in_configuration, result
    assert_last_id app, nil
    assert_sample_messages_states msgs
  end
  
  def test_failed_when_wrong_interface
    app = create_app_with_interface('myapp', 'mypass', 'rss', { :url => 'http://example.com' })
    msgs = sample_messages(app)
    setup_null_http app
    
    result = job app
    assert_equal :error_wrong_interface, result
    assert_last_id app, nil
    assert_sample_messages_states msgs
  end
  
  def test_failed_when_obtaining_last_guid
    app = setup_app
    msgs = sample_messages(app)
    setup_http app, 
      :expects_post => false,
      :head_response => mock_http_failure
    
    result = job app
    
    assert_equal :error_obtaining_last_id, result
    assert_last_id app, nil
    assert_sample_messages_states msgs
  end
  
  def test_batch_returns_success_pending
    app = setup_app :max_tries => 5
    msgs =  new_at_message app, (0..20), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (21..100), 'protocol', 'queued', 0
    app.set_last_guid(msgs[20].guid)
    
    setup_http app, :msgs_posted => (21..30), 
      :expects_head => false, 
      :post_etag => msgs[30].guid

    result = batch app
        
    assert_equal :success_pending, result
    assert_last_id app, msgs[30].guid
    assert_msgs_states msgs[0..30], 'confirmed', 1 
    assert_msgs_states msgs[31..100], 'queued', 0
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_full
    app = setup_app :max_tries => 5
    msgs =  new_at_message app, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (20...100), 'protocol', 'queued', 0
    app.set_last_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(app) do
      assert current < 101
      if current == 100
        setup_http app, 
          :expects_post => false, 
          :expects_head => false
      else
        setup_http app, 
          :msgs_posted => (current...current+10), 
          :expects_head => false, 
          :post_etag => msgs[current+9].guid
        current += 10
      end
    end
        
    assert_equal :success, result
    assert_last_id app, msgs[99].guid
    assert_msgs_states msgs[0...100], 'confirmed', 1 
  end
  
  def test_perform_runs_until_no_more_messages_with_last_batch_partial
    app = setup_app :max_tries => 5
    msgs =  new_at_message app, (0...20), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (20...105), 'protocol', 'queued', 0
    app.set_last_guid(msgs[19].guid)
    
    current = 20
    result = job_with_callback(app) do
      max = if current == 100 then 104 else current + 9 end
      setup_http app, 
        :msgs_posted => (current..max), 
        :expects_head => false, 
        :post_etag => msgs[max].guid
      current = max + 1
    end
        
    assert_equal :success, result
    assert_last_id app, msgs[104].guid
    assert_msgs_states msgs[0...105], 'confirmed', 1 
  end
  
  private
  
  def assert_last_id(app, last_id)
    afterapp = Application.find_by_id app.id
    assert_equal last_id, afterapp.configuration[:last_guid]
  end
  
  def setup_app(cfg = {})
    create_app_with_interface('app', 'pass', 'qst', { :last_guid => nil, :url => 'http://example.com', :cred_user => 'theuser', :cred_pass => 'thepass' }.merge(cfg))
  end
  
  def setup_app_unauth(cfg = {})
    create_app_with_interface('app', 'pass', 'qst', { :last_guid => nil, :url => 'http://example.com'}.merge(cfg))
  end
  
  def setup_null_http(app)
    setup_http app, :auth => false, 
      :expects_head => false,
      :expects_post => false,
      :expects_init => false
  end
  
  def setup_http(app, opts)
    cfg = { 
      :auth => true, 
      :expects_head => true,  
      :expects_post => true,  
      :msgs_posted => (0..0),
      :expects_init => true,
      :url_host => 'example.com',
      :url_port => 80,
      :url_path => 'incoming',
    }.merge(opts)
    
    cfg[:head_response] = mock_http_success('etag' => cfg[:head_etag]) if cfg[:head_response].nil?
    cfg[:post_response] = mock_http_success('etag' => cfg[:post_etag]) if cfg[:post_response].nil?
    
    http = mock_http(cfg[:url_host], cfg[:url_port], cfg[:expects_init])
    http.expects(:basic_auth).with('theuser', 'thepass') if cfg[:auth]
    http.expects(:head).with(cfg[:url_path]).returns(cfg[:head_response]) if cfg[:expects_head]
    http.expects(:post).with() { |url, data|      
      assert_equal cfg[:url_path], url
      assert_xml_msgs data, cfg[:msgs_posted]
    }.returns(cfg[:post_response]) if cfg[:expects_post]
    http
  end
  
  def sample_messages app
    msgs =  new_at_message app, (0..2), 'protocol', 'confirmed', 1
    msgs += new_at_message app, (3..5), 'protocol', 'delivered', 3
    msgs += new_at_message app, (6..7), 'protocol', 'failed', 5
    msgs += new_at_message app, (8..10), 'protocol', 'queued', 0
    msgs
  end
  
  def assert_sample_messages_states msgs
    assert_msgs_states msgs[0..2], 'confirmed', 1 
    assert_msgs_states msgs[3..5], 'delivered', 3
    assert_msgs_states msgs[6..7], 'failed', 5
    assert_msgs_states msgs[8..10], 'queued', 0
  end
  
  class CallbackJob < PushQstMessageJob
    def initialize(app_id, block)
      super app_id
      @block = block
    end
    def perform_batch
      @block.call
      super
    end
  end
  
  def job_with_callback(app, &block)
    j = CallbackJob.new app.id, block
    j.perform
  end
  
  def job(app)
    j = PushQstMessageJob.new app.id
    j.perform
  end
  
  def batch(app)
    j = PushQstMessageJob.new app.id
    j.perform_batch
  end
  
end