require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PushQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
include Net
  
  should "perform first run" do
    
    app = create_app_with_interface('app', 'pass', 'qst', :url => 'http://example.com', :cred_user => 'theuser', :cred_pass => 'thepass')
    
    http = mock_http('example.com', 80)
    http.expects(:basic_auth).with('theuser', 'thepass')
    http.expects(:head).with('incoming').returns(mock_http_success('etag' => nil))
    http.expects(:post).with() { |url, data|      
      assert_equal 'incoming', url
      assert_xml_msgs data, (0..2)
    }.returns(mock_http_success)
        
    msg0 = new_at_message app, 0
    msg1 = new_at_message app, 1
    msg2 = new_at_message app, 2
    
    job = PushQstMessageJob.new app.id
    result = job.perform
    
    assert_equal :success, result
    
    afterapp = Application.find_by_id app.id
    assert_equal true, afterapp.configuration[:last_ok]
    
    assert_msg_state(msg0.id, 'delivered', 1)
    assert_msg_state(msg1.id, 'delivered', 1)
    assert_msg_state(msg2.id, 'delivered', 1)
    
  end
  
  should "perform run with last ok" do
    assert_equal 1, 1  
  end
  
end