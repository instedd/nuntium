require 'test_helper'

class IncomingControllerTest < ActionController::TestCase
  test "get last message id" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    create_message(app, 0)
    create_message(app, 1)
    
    app2, chan2 = create_app_and_channel('user2', 'pass2', 'chan2', 'chan_pass2')
    create_message(app2, 2)
  
    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'chan_pass')
    head :index
    
    assert_response :ok
    assert_equal "someguid 1", @response.headers['ETag']
  end
  
  test "get last message id not exists" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
  
    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'chan_pass')
    head :index
    
    assert_response :ok
    assert_equal "", @response.headers['ETag']
  end
  
  test "can't read" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    
    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'chan_pass')
    get :index
    
    assert_response :not_found
  end
  
  test "push message" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
  
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
        </message>
      </messages>
    eos
    
    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'chan_pass')
    post :create
    
    assert_response :ok
    assert_equal "someguid", @response.headers['ETag']
    
    messages = ATMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    assert_equal app.id, msg.application_id
    assert_equal "Hello!", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("2008-09-24T17:12:57-03:00"), msg.timestamp
  end
  
  test "get last message id not authorized" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')

    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'wrong_chan_pass')
    head :index
    
    assert_response 401
  end
  
  test "push messages not authorized" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')

    @request.env['HTTP_AUTHORIZATION'] = auth('user', 'wrong_chan_pass')
    post :create
    
    assert_response 401
  end
    
  # Utility methods follow
  
  def create_app_and_channel(user, pass, chan, chan_pass)
    app = Application.new
    app.name = user
    app.password = Digest::MD5.hexdigest(pass)
    app.save!
    
    channel = Channel.new
    channel.application_id = app.id
    channel.name = chan
    channel.configuration = { :password => Digest::MD5.hexdigest(chan_pass) }
    channel.kind = :qst
    channel.save!
    
    [app, channel]
  end
  
  def create_message(app, i)
    msg = ATMessage.new
    msg.application_id = app.id
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = "Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = Time.parse("03 Jun #{2003 + i} 09:39:21 GMT")
    msg.save
  end
  
  def auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + Digest::MD5.hexdigest(pass))
  end
    
end
