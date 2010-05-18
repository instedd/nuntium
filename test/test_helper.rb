ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/blueprints")
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

  def setup
    Rails.cache.clear
    Sham.reset
  end
    
  # Returns the string to be used for HTTP_AUTHENTICATION header
  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
  end
  
  def mock_http_request(kind, path, name='request', user=nil, pass=nil, headers={})
    request = mock(name) do
      expects(:basic_auth).with(user, pass) unless user.nil? or pass.nil?
      headers.each_pair do |k,v|
        expects(:[]=).with(k,v)
      end  
    end
    kind.expects(:new).with(path).returns(request)
    request
  end
  
  # Returns a new mock for a failed http response with the specified headers and code
  def mock_http_failure(code = '400', message = 'Mocked error message', headers = {})
    require 'net/http'
    response = mock do
      stubs(:code => code)
      stubs(:message => message)
      headers.each_pair do |k,v|
        stubs(:[]).with(k).returns(v)
      end  
    end
    response
  end
  
  # Returns a new mock for a successful http response with the specified headers
  def mock_http_success(headers = {})
    require 'net/http'
    response = mock do
      stubs(:code => '200')
      headers.each_pair do |k,v|
        stubs(:[]).with(k).returns(v)
      end  
    end
    response
  end
  
  # Returns a new mock for a successful http response with a body and the specified headers
  def mock_http_success_body(body, headers = {})
    require 'net/http'
    response = mock_http_success(headers)
    response.stubs(:body => body)
    response
  end

  # Returns a new Net:HTTP mocked object and applies all expectations to it
  # Will be returned when the user creates a new instance
  def mock_http(host, port='80', expected=true, ssl=false, &block)
    require 'net/http'
    http = mock('http', &block) 
    if ssl
      http.expects(:use_ssl=).with(true) 
      http.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE) 
    end
    if expected
      Net::HTTP.expects(:new).with(host, port).returns(http)
    else
      Net::HTTP.stubs(:new).with(host, port).returns(http)
    end
    http
  end

  # Creates an application with a specific interface and configuration
  def create_application_with_interface(account_name, account_pass, interface, cfg)
    account = Account.create!(:name => account_name, :password => account_pass)
    application = Application.new(:account_id => account.id, :name => account_name, :interface => interface, :password => account_pass)
    application.configuration = {}
    cfg.each_pair do |k,v| application.configuration[k] = v end
    application.save!
    application
  end
  
  # Creates an account and a qst channel with the given values.
  # Returns the tupple [account, channel]
  def create_account_and_channel(account_name, account_pass, chan_name, chan_pass, kind, protocol = 'protocol')
    account = Account.new
    account.name = account_name
    account.password = account_pass
    account.save!
    
    channel = create_channel account, chan_name, chan_pass, kind, protocol
    
    [account, channel]
  end
  
  def create_channel(account, name, pass, kind, protocol = 'protocol')
    channel = Channel.new
    channel.account_id = account.id
    channel.name = name
    channel.protocol = protocol
    channel.configuration = { :password => pass }
    channel.kind = kind
    channel.direction = Channel::Bidirectional
    channel.save!
    
    channel
  end
  
  def create_app(account, i = nil)
    Application.create! :account_id => account.id, :name => (i.nil? ? 'application' : "application#{i}"), :interface => 'rss', :password => 'app_pass'
  end
  
  # Creates a new message of the specified kind with values according to i
  def new_message(account, i, kind, protocol = 'protocol', state = 'queued', tries = 0)
    if i.respond_to? :each
      msgs = []
      i.each { |j| msgs << new_message(account, j, kind, protocol, state, tries) } 
      return msgs
    else
      msg = kind.new
      fill_msg msg, account, i, protocol, state, tries
      msg.save!
      return msg
    end
  end
  
  # Creates an ATMessage that belongs to account and has values according to i
  def new_at_message(application, i, protocol = 'protocol', state = 'queued', tries = 0)
    msg = new_message application.account, i, ATMessage, protocol, state, tries
    if msg.respond_to? :each
      msg.each{|x| x.application_id = application.id, x.save!}   
    else
      msg.application_id = application.id
      msg.save!
    end
    msg
  end
  
  # Creates an AOMessage that belongs to account and has values according to i
  def new_ao_message(account, i, protocol = 'protocol', state = 'queued', tries = 0)
    new_message account, i, AOMessage, protocol, state, tries
  end
  
  # Fills the values of an existing message
  def fill_msg(msg, account, i, protocol = 'protocol', state = 'queued', tries = 0)
    msg.account_id = account.id
    msg.subject = "Subject of the message #{i}"
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = protocol + "://Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = time_for_msg i
    msg.state = state
    msg.tries = tries
  end
  
  # Returns a specific time for a message with index i
  def time_for_msg(i)
      Time.at(946702800 + 86400 * (i+1)).getgm 
  end
  
  # Sets current time as a stub on Time.now
  def set_current_time(time=Time.at(946702800).utc)
    Time.stubs(:now).returns(time)
  end
    
  # Returns base time to be used for tests in utc
  def base_time
    return Time.at(946702800).utc
  end
  
  # Given a message id, checks that message in the db has the specified state and tries
  def assert_msg_state(msg_or_id, state, tries,kind=ATMessage)
    msg_id = msg_or_id.id unless msg_or_id.kind_of? String
    msg = kind.find_by_id(msg_id)
    assert_not_nil msg, "message with id #{msg_id} not found"
    assert_equal state, msg.state, "message with id #{msg_id} state does not match"
    assert_equal tries, msg.tries, "message with id #{msg_id} tries does not match"
  end
  
  # Given a list of message or ids, checks that each message in the db has the specified state and tries
  def assert_msgs_states(msg_ids, state, tries, kind=ATMessage)
    msg_ids.each { |msg| assert_msg_state msg, state, tries, kind }
  end
  
  # Asserts all values for a message constructed with new or fill
  def assert_msg(msg, account, i, protocol = 'protocol')
    assert_equal account.id, msg.account_id, 'message account id'
    assert_equal "Subject of the message #{i}", msg.subject, 'message subject'
    assert_equal "Body of the message #{i}", msg.body, 'message body'
    assert_equal "Someone #{i}", msg.from, 'message from'
    assert_equal protocol + "://Someone else #{i}", msg.to, 'message to' 
    assert_equal "someguid #{i}", msg.guid, 'message guid' 
    assert_equal time_for_msg(i), msg.timestamp, 'message timestamp' 
    assert_equal 'queued', msg.state, 'message status'
  end
  
  # Creates a new QSTOutgoingMessage with guid "someguid #{i}"
  def new_qst_outgoing_message(chan, ao_message_id)
    msg = QSTOutgoingMessage.new
    msg.channel_id = chan.id
    msg.ao_message_id = ao_message_id
    msg.save!
  end
  
  def assert_shows_message(msg)
    assert_select "message[id=?]", msg.guid
    assert_select "message[from=?]", msg.from
    assert_select "message[to=?]", msg.to
    assert_select "message[when=?]", msg.timestamp.iso8601
    assert_select "message text", msg.subject.nil? ? msg.body : msg.subject + " - " + msg.body
    
    msg.custom_attributes.each do |name, value|
      assert_select "message property[name=?][value=?]", name, value, :count => 1
    end
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
  
  def new_channel(account, name, options = {})
    chan = Channel.new(:account_id => account.id, :name => name, :kind => 'qst_server', :protocol => 'sms', :direction => Channel::Bidirectional);
    options.each {|key, value| chan.send("#{key}=", value)}
    chan.configuration = {:url => 'a', :user => 'b', :password => 'c'};
    chan.save!
    chan
  end
  
  def assert_validates_configuration_presence_of(chan, field)
    chan.configuration.delete field
    assert !chan.save
  end
  
  def assert_validates_configuration_ok(chan)
    assert chan.save
  end
  
  def assert_handler_should_enqueue_ao_job(chan, job_class)
    chan.save!
    
    jobs = []
    Queues.subscribe_ao(chan) { |header, job| jobs << job; header.ack; sleep 0.3 }
    
    msg = AOMessage.new(:account_id => chan.account_id, :channel_id => chan.id)
    chan.handler.handle(msg)
    
    sleep 0.3
    
    assert_equal 1, jobs.length
    assert_equal job_class, jobs[0].class
    assert_equal msg.id, jobs[0].message_id
    assert_equal chan.id, jobs[0].channel_id
    assert_equal chan.account_id, jobs[0].account_id
  end
end
