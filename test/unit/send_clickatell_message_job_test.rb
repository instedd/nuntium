require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class SendClickatellMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  should "perform" do
    request = mock('Net::HTTPRequest')
  
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ID: msgid')
      
    host = URI::parse('https://api.clickatell.com')
      
    uri = '/http/sendmsg'
    uri += '?api_id=api1'
    uri += '&user=user1'
    uri += '&password=pass1'
    # uri += '&from=1234'
    uri += '&to=5678'
    uri += '&text=text+me'
    
    Net::HTTP.expects(:new).with(host.host, host.port).returns(request)
    request.expects('use_ssl=').with(true)
    request.expects('verify_mode=').with(OpenSSL::SSL::VERIFY_NONE)
    request.expects(:get).with(uri).returns(response)
    
    app = Application.create(:name => 'app', :password => 'pass')
    chan = Channel.create(:application_id => app.id, :name => 'chan', :protocol => 'protocol', :kind => 'clickatell', 
      :configuration => {:api_id => 'api1', :user => 'user1', :password => 'pass1'})
    msg = AOMessage.create(:application_id => app.id, :from => 'sms://1234', :to => 'sms://5678', :body => 'text me', :state => 'pending')
      
    job = SendClickatellMessageJob.new(app.id, chan.id, msg.id)
    result = job.perform
    
    assert_equal 'msgid', result
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end