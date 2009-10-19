require 'test_helper'

class IncomingControllerTest < ActionController::TestCase
  test "get last message id" do
    create_first_message
    create_second_message
  
    head :index
    
    assert_response :ok
    assert_equal "someguid 2", @response.headers['ETag']
  end
  
  test "get last message id not exists" do
    head :index
    
    assert_response :ok
    assert_equal "", @response.headers['ETag']
  end
  
  test "can't read" do
    get :index
    
    assert_response :not_found
  end
  
  test "push message" do
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
        </message>
      </messages>
    eos
    post :create
    
    assert_response :ok
    assert_equal "someguid", @response.headers['ETag']
    
    messages = ATMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    assert_equal "Hello!", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("2008-09-24T17:12:57-03:00"), msg.timestamp
  end
    
  # Utility methods follow
  
  def create_first_message
    msg = ATMessage.new
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.to = "Someone else"
    msg.guid = "someguid"
    msg.timestamp = Time.parse("Tue, 03 Jun 2003 09:39:21 GMT")
    msg.save
  end
  
  def create_second_message
    msg = ATMessage.new
    msg.body = "Body of the message 2"
    msg.from = "Someone 2"
    msg.to = "Someone else 2"
    msg.guid = "someguid 2"
    msg.timestamp = Time.parse("Thu, 03 Jun 2004 09:39:21 GMT")
    msg.save
  end
    
end
