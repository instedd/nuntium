require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PullQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  @separate_msg_times_by_year = false
  
  def test_perform_first_run
    app = setup_app
    msgs = sample_messages app, (3..8)
    
    setup_http app,
      :get_msgs => msgs
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
  end
  
  def test_perform_with_etag
    app = setup_app 
    msgs = sample_messages app, (5..8)
    app.stubs(:last_ao_guid => 'lastetag')
    
    setup_http app,
      :get_msgs => msgs,
      :etag => 'lastetag' 
      
    result = job app
    
    assert_equal :success, result
    assert_last_id app, msgs[-1].guid
  end
  
  private
  
  def assert_last_id(app, last_id)
    afterapp = Application.find_by_id app.id
    assert_equal last_id, afterapp.configuration[:last_ao_guid]
  end
  
  def setup_app(cfg = {})
    mock_app_with_interface'myid', 'app', 'pass', 'qst', 
      { :last_ao_guid => nil, 
        :url => 'http://example.com', 
        :cred_user => 'theuser', 
        :cred_pass => 'thepass' }.merge(cfg)
  end
  
  def setup_app_unauth(cfg = {})
    mock_app_with_interface'myid', 'app', 'pass', 'qst', 
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
      :url_path => 'outgoing',
      :etag => nil,
      :headers => nil
    }.merge(opts)
    
    if cfg[:expects_get]
      cfg[:get_body] ||= AOMessage.write_xml(cfg[:get_msgs]) unless cfg[:not_modified] 
      cfg[:get_response] ||= cfg[:not_modified] ? mock_http_failure(304, 'Not modified') : mock_http_success_body(cfg[:get_body])
      cfg[:headers] ||= { 'http_if_none_match' => cfg[:etag] } unless cfg[:etag].nil?
    end
    
    http = mock_http(cfg[:url_host], cfg[:url_port], cfg[:expects_init])
    http.expects(:basic_auth).with('theuser', 'thepass') if cfg[:auth]
    http.expects(:get).with(cfg[:url_path], cfg[:headers]).returns(cfg[:get_response]) if cfg[:expects_get]
    
    http
  end
  
  def sample_messages app, range 
    msgs = []
    range.each do |i| 
      msg = AOMessage.new
      fill_msg msg, app, i, "protocol"
      app.expect(:route).with() { |m| 
        m.guid == msg.guid and
        m.from == msg.from and
        m.to == msg.to and
        m.body == msg.subject_and_body and
        m.timestamp == msg.timestamp
      }
      msgs << msg
    end
    msgs
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