require 'test_helper'
require 'uri'
require 'net/http'
require 'mocha'

class SendClickatellMessageJobTest < ActiveSupport::TestCase
  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ID: msgid')
      
    uri = 'https://api.clickatell.com/http/sendmsg'
    uri += '?api_id=api1'
    uri += '&user=user1'
    uri += '&password=pass1'
    uri += '&from=1234'
    uri += '&to=5678'
    uri += '&text=textme'
    
    Net::HTTP.expects(:request_get).with(uri).returns(response)
    
    app = Application.create(:name => 'app', :password => 'pass')
    chan = Channel.create(:application_id => app.id, :name => 'chan', :protocol => 'protocol', :kind => 'clickatell', 
      :configuration => {:api_id => 'api1', :user => 'user1', :password => 'pass1'})
    msg = AOMessage.create(:application_id => app.id, :from => '1234', :to => '5678', :body => 'textme', :state => 'pending')
      
    job = SendClickatellMessageJob.new(app.id, chan.id, msg.id)
    result = job.perform
    
    assert_equal 'msgid', result
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end