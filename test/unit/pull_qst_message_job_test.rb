require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'

class PullQstMessageJobTest < ActiveSupport::TestCase
  include Net
  
  test "perform first run" do
    application = setup_application
    msgs = sample_messages application, (3..8)
    
    setup_http application,
      :get_msgs => msgs
      
    result = job application
    
    assert_equal :success, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs
  end
  
  test "perform first run no messages" do
    application = setup_application 
    
    setup_http application,
      :not_modified => true
      
    result = job application
    
    assert_equal :success, result
    assert_last_id application, nil
  end

 test "perform with etag" do
    application = setup_application 
    msgs = sample_messages application, (5..8)
    application.set_last_ao_guid 'lastetag'
    
    setup_http application,
      :get_msgs => msgs,
      :etag => 'lastetag' 
      
    result = job application
    
    assert_equal :success, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs
  end
  
  test "perform with etag on ssl" do
    application = setup_application :interface_url => 'https://example.com'
    msgs = sample_messages application, (5..8)
    application.set_last_ao_guid 'lastetag'
    
    setup_http application,
      :get_msgs => msgs,
      :etag => 'lastetag',
      :use_ssl => true,
      :url_port => 443
      
    result = job application
    
    assert_equal :success, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs
  end
  
  test "perform with etag not modified" do
    application = setup_application 
    application.set_last_ao_guid 'lastetag'
    
    setup_http application,
      :etag => 'lastetag',
      :not_modified => true
      
    result = job application
    
    assert_equal :success, result
    assert_last_id application, 'lastetag'
  end

  test "perform pulls until not modified" do
    application = setup_application 
    msgs =  sample_messages application, (0...10)
    msgs += sample_messages application, (10...60)
    application.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(application) do
      assert current <= 60
      data = current < 60 ? { :get_msgs => msgs[current...current+10] } : { :not_modified => true }
      setup_http application, data.merge({:etag => msgs[current-1].guid})
      current += 10          
    end
    
    assert_equal :success, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs[10 .. -1]
  end
  
  test "perform pulls until size less than max" do
    application = setup_application 
    msgs =  sample_messages application, (0...10)
    msgs += sample_messages application, (10...65)
    application.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(application) do
      assert current <= 60
      setup_http application, :etag => msgs[current-1].guid, :get_msgs => msgs[current...current+10] 
      current += 10          
    end
    
    assert_equal :success, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs[10 .. -1]
  end
  
  test "perform pulls until failure" do
    application = setup_application 
    msgs =  sample_messages application, (0...10)
    msgs += sample_messages application, (10...60)
    application.set_last_ao_guid msgs[9].guid
    
    current = 10
    result = job_with_callback(application) do
      assert current <= 60
      if current == 60
        setup_http application, :etag => msgs[current-1].guid, :get_response => mock_http_failure
      else
        setup_http application, :etag => msgs[current-1].guid, :get_msgs => msgs[current...current+10]
      end
      current += 10          
    end
    
    assert_equal :error_pulling_messages, result
    assert_last_id application, msgs[-1].guid
    assert_sample_messages application, msgs[10 .. -1]
  end

  test "failure response code" do
    application = setup_application 
    application.set_last_ao_guid 'lastetag'
    
    setup_http application,
      :get_response => mock_http_failure,
      :etag => 'lastetag' 
      
    result = job application
    
    assert_equal :error_pulling_messages, result
    assert_last_id application, 'lastetag'
  end

  test "failure processing response" do
    application = setup_application 
    application.set_last_ao_guid 'lastetag'
    
    setup_http application,
      :etag => 'lastetag',
      :get_body => 
      <<-XML
      <?xml version="1.0" encoding="UTF-8" ?>
      <messages><messa
      XML
      
    result = job application
    
    assert_equal :error_processing_messages, result
    assert_last_id application, 'lastetag'
  end
  
  private
  
  def assert_last_id(application, last_id)
    afterapplication = Application.find_by_id application.id
    assert_equal last_id, afterapplication.configuration[:last_ao_guid]
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
    setup_http application, 
      :auth => false, 
      :expects_get => false,
      :expects_init => false
  end
  
  def setup_http(application, opts)
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
  
  def assert_sample_messages application, msgs
    msgs.each do |expected| 
      msg = AOMessage.find_by_guid expected.guid
      assert_not_nil msg
      [:subject_and_body, :from, :to, :guid, :timestamp].each do |field|
        assert_equal expected.send(field), msg.send(field)
      end
      assert_equal application.account.id, msg.account_id
    end
  end
  
  def sample_messages application, range 
    msgs = []
    range.each do |i|
      msgs << AOMessage.make_unsaved
    end
    msgs
  end
  
  class CallbackJob < PullQstMessageJob
    def initialize(application_id, block)
      super application_id
      @block = block
    end
    def perform_batch
      @block.call
      super
    end
  end
  
  def job_with_callback(application, &block)
    j = CallbackJob.new application.id, block
    j.perform
  end
  
  def job(application)
    j = PullQstMessageJob.new application.id
    j.perform
  end
  
  def batch(application)
    j = PullQstMessageJob.new application.id
    j.perform_batch
  end
  
end
