ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'base64'
require 'digest/md5'
require 'digest/sha2'
require 'shoulda'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # Returns the string to be used for HTTP_AUTHENTICATION header
  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
  end
  
  # Creates an app and a qst channel with the given values.
  # Returns the tupple [application, channel]
  def create_app_and_channel(app_name, app_pass, chan_name, chan_pass, kind, protocol = 'protocol')
    app = Application.new
    app.name = app_name
    app.password = app_pass
    app.save!
    
    channel = create_channel app, chan_name, chan_pass, kind, protocol
    
    [app, channel]
  end
  
  def create_channel(app, name, pass, kind, protocol = 'protocol')
    channel = Channel.new
    channel.application_id = app.id
    channel.name = name
    channel.protocol = protocol
    channel.configuration = { :password => pass }
    channel.kind = kind
    channel.direction = Channel::Both
    channel.save!
    
    channel
  end
  
  # Creates an ATMessage that belongs to app and has values according to i
  def new_at_message(app, i, protocol = 'protocol')
    msg = ATMessage.new
    fill_msg msg, app, i, protocol
    msg.save!
    
    msg
  end
  
  # Creates an AOMessage that belongs to app and has values according to i
  def new_ao_message(app, i, protocol = 'protocol')
    msg = AOMessage.new
    fill_msg msg, app, i, protocol
    msg.save!
    
    msg
  end
  
  def fill_msg(msg, app, i, protocol = 'protocol')
    msg.application_id = app.id
    msg.subject = "Subject of the message #{i}"
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = protocol + "://Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = Time.parse("03 Jun #{2003 + i} 09:39:21 GMT")
    msg.state = 'queued'
  end
  
  # Creates a new QSTOutgoingMessage with guid "someguid #{i}"
  def new_qst_outgoing_message(chan, i)
    msg = QSTOutgoingMessage.new
    msg.channel_id = chan.id
    msg.guid = "someguid #{i}"
    msg.save
  end
  
  def assert_shows_message(msg)
    assert_select "message[id=?]", msg.guid
    assert_select "message[from=?]", msg.from
    assert_select "message[to=?]", msg.to
    assert_select "message[when=?]", msg.timestamp.iso8601
    assert_select "message text", msg.subject.nil? ? msg.body : msg.subject + " - " + msg.body
  end
  
  def assert_shows_message_as_rss_item(msg)
    if msg.subject.nil?
      assert_select "item title", msg.body
      assert_select "item description", {:count => 0}
    else
      assert_select "item title", msg.subject
      assert_select "item description", msg.body
    end
    
    assert_select "item author", msg.from
    assert_select "item to", msg.to
    assert_select "item guid", msg.guid
    assert_select "item pubDate", msg.timestamp.rfc822
  end
  
end
