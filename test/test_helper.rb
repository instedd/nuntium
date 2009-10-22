ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'base64'
require 'digest/md5'
require 'digest/sha2'

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
  def create_app_and_channel(app_name, app_pass, chan_name, chan_pass)
    app = Application.new
    app.name = app_name
    app.password = app_pass
    app.save!
    
    channel = create_channel app, chan_name, chan_pass
    
    [app, channel]
  end
  
  def create_channel(app, name, pass)
    channel = Channel.new
    channel.application_id = app.id
    channel.name = name
    channel.configuration = { :password => pass }
    channel.kind = :qst
    channel.save!
    
    channel
  end
  
  # Creates an ATMessage that belongs to app and has values according to i
  def new_at_message(app, i)
    msg = ATMessage.new
    fill_msg msg, app, i
    msg.save!
    
    msg
  end
  
  # Creates an AOMessage that belongs to app and has values according to i
  def new_ao_message(app, i)
    msg = AOMessage.new
    fill_msg msg, app, i
    msg.save!
    
    msg
  end
  
  def fill_msg(msg, app, i)
    msg.application_id = app.id
    msg.subject = "Subject of the message #{i}"
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = "Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = Time.parse("03 Jun #{2003 + i} 09:39:21 GMT")
  end
  
  # Creates a new QSTOutgoingMessage with guid "someguid #{i}"
  def new_qst_outgoing_message(chan, i)
    msg = QSTOutgoingMessage.new
    msg.channel_id = chan.id
    msg.guid = "someguid #{i}"
    msg.save
  end
  
end
