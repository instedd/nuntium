require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PullQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  def test_perform_first_run
    app = setup_app
    msgs = sample_messages app, (3..8)
    
    setup_http app,
      :get_msgs => msgs
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (3..8)
  end
  
  def test_perform_first_run_no_messages
    app = setup_app 
    
    setup_http app,
      :not_modified => true
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, nil
  end

  def test_perform_with_etag
    app = setup_app 
    msgs = sample_messages app, (5..8)
    app.set_last_ao_guid 'lastetag'
    
    setup_http app,
      :get_msgs => msgs,
      :etag => 'lastetag' 
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (5..8)
  end
  
  def test_perform_with_etag_on_ssl
    app = setup_app :url => 'https://example.com'
    msgs = sample_messages app, (5..8)
    app.set_last_ao_guid 'lastetag'
    
    setup_http app,
      :get_msgs => msgs,
      :etag => 'lastetag',
      :use_ssl => true,
      :url_port => 443
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (5..8)
  end
  
  def test_perform_with_etag_not_modified
    app = setup_app 
    app.set_last_ao_guid 'lastetag'
    
    setup_http app,
      :etag => 'lastetag',
      :not_modified => true
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, 'lastetag'
  end

  def test_perform_pulls_until_not_modified
    app = setup_app 
    msgs =  sample_messages app, (0...10)
    msgs += sample_messages app, (10...60)
    app.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(app) do
      assert current <= 60
      data = current < 60 ? { :get_msgs => msgs[current...current+10] } : { :not_modified => true }
      setup_http app, data.merge({:etag => msgs[current-1].guid})
      current += 10          
    end
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (10...60)
  end
  
  def test_perform_pulls_until_size_less_than_max
    app = setup_app 
    msgs =  sample_messages app, (0...10)
    msgs += sample_messages app, (10...65)
    app.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(app) do
      assert current <= 60
      setup_http app, :etag => msgs[current-1].guid, :get_msgs => msgs[current...current+10] 
      current += 10          
    end
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (10...65)
  end
  
  def test_perform_pulls_until_failure
    app = setup_app 
    msgs =  sample_messages app, (0...10)
    msgs += sample_messages app, (10...60)
    app.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(app) do
      assert current <= 60
      if current == 60
        setup_http app, :etag => msgs[current-1].guid, :get_response => mock_http_failure
      else
        setup_http app, :etag => msgs[current-1].guid, :get_msgs => msgs[current...current+10]
      end
      current += 10          
    end
    
    assert_equal :error_pulling_messages, result
    assert_last_id app, msgs[-1].guid
    assert_sample_messages app, (10...60)
  end

  def test_failure_response_code
    app = setup_app 
    app.set_last_ao_guid 'lastetag'
    
    setup_http app,
      :get_response => mock_http_failure,
      :etag => 'lastetag' 
      
    result = job app
    
    assert_equal :error_pulling_messages, result
    assert_last_id app, 'lastetag'
  end

  def test_failure_processing_response
    app = setup_app 
    app.set_last_ao_guid 'lastetag'
    
    setup_http app,
      :etag => 'lastetag',
      :get_body => 
      <<-XML
      <?xml version="1.0" encoding="UTF-8" ?>
      <messages><messa
      XML
      
    result = job app
    
    assert_equal :error_processing_messages, result
    assert_last_id app, 'lastetag'
  end
  
  private
  
  def assert_last_id(app, last_id)
    afterapp = Application.find_by_id app.id
    assert_equal last_id, afterapp.configuration[:last_ao_guid]
  end
  
  def setup_app(cfg = {})
    create_app_with_interface 'app', 'pass', 'qst', 
      { :last_ao_guid => nil, 
        :url => 'http://example.com', 
        :cred_user => 'theuser', 
        :cred_pass => 'thepass' }.merge(cfg)
  end
  
  def setup_app_unauth(cfg = {})
    create_app_with_interface  'app', 'pass', 'qst', 
      { :last_ao_guid => nil, 
        :url => 'http://example.com' }.merge(cfg)
  end
  
  def setup_null_http(app)
    setup_http app, 
      :auth => false, 
      :expects_get => false,
      :expects_init => false
  end
  
  def setup_http(app, opts)
    cfg = { 
      :auth => true, 
      :expects_get => true,
      :expects_init => true,
      :not_modified => false,
      :get_msgs => [],
      :get_body => nil,
      :get_response => nil,
      :url_host => 'example.com',
      :url_port => 80,
      :url_path => 'outgoing?max=10',
      :etag => nil,
      :headers => nil,
      :use_ssl => false
    }.merge(opts)
    
    if cfg[:expects_get]
      cfg[:get_body] ||= AOMessage.write_xml(cfg[:get_msgs]) unless cfg[:not_modified] 
      cfg[:get_response] ||= cfg[:not_modified] ? mock_http_failure('304', 'Not modified') : mock_http_success_body(cfg[:get_body])
      cfg[:headers] ||= { 'if-none-match' => cfg[:etag] } unless cfg[:etag].nil?
      cfg[:headers] ||= {}
    end
    
    http = mock_http(cfg[:url_host], cfg[:url_port], cfg[:expects_init], cfg[:use_ssl])
    
    if cfg[:expects_get] and cfg[:expects_init]
      user = cfg[:auth] ? 'theuser' : nil
      pass = cfg[:auth] ? 'thepass' : nil
      get = mock_http_request(Net::HTTP::Get, cfg[:url_path], 'get', user, pass, cfg[:headers])
      http.expects(:request).with(get).returns(cfg[:get_response])
    end
    
    http
  end
  
  def assert_sample_messages app, range
    range.each do |i| 
      msg = AOMessage.find_by_guid "someguid #{i}"
      assert_not_nil msg, "message #{i} is nil"
      assert_deserialized_msg msg, app, i
      assert_equal app.id, msg.application_id
    end
  end
  
  def sample_messages app, range 
    msgs = []
    range.each do |i| 
      msg = AOMessage.new
      fill_msg msg, app, i, "protocol"
      msgs << msg
    end
    msgs
  end
  
  class CallbackJob < PullQstMessageJob
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
    j = PullQstMessageJob.new app.id
    j.perform
  end
  
  def batch(app)
    j = PullQstMessageJob.new app.id
    j.perform_batch
  end
  
end