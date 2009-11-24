require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class PushQstMessageJobTest < ActiveSupport::TestCase
include Mocha::API
  
  should "perform first run" do
    
    http = mock('Net::HTTP')
    
    response = mock('Net::HTTPOk') do
      stubs(:code => '200', :[] => nil)
    end
    
    head_response = mock('Net::HTTPOk') do
      stubs(:code => '200')
      expects(:[]).with('etag').returns(nil)
    end
    
    app = Application.create(:name => 'app', :password => 'pass', :interface => 'qst')
    app.configuration = {}
    app.configuration[:url] = 'http://example.com'
    app.configuration[:cred_user] = 'theuser'
    app.configuration[:cred_pass] = 'thepass'
    app.save
    
    Net::HTTP.expects(:new).with('example.com', 80).returns(http)
    http.expects(:basic_auth).with('theuser', 'thepass')
    http.expects(:head).with('incoming').returns(head_response)
    
    http.expects(:post).with() { | url, data |      
      assert_equal 'incoming', url
      assert_xml data, (0..2)
    }.returns(response)
    
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
end