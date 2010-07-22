ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/blueprints")
require 'test_help'
require 'base64'
require 'digest/md5'
require 'digest/sha2'
require 'shoulda'
require 'mocha'

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
  
  include Mocha::API

  def setup
    Rails.cache.clear
    Sham.reset
    WorkerQueue.publish_notification_delay = 0
  end
  
  def expect_get(options = {})
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(options[:returns].new 'x', 'x', 'x')
    
    resource2 = mock('RestClient::Resource')
    resource2.expects('get').returns(response)
    
    resource = mock('RestClient::Resource')
    resource.expects('[]').with("?#{options[:query_params].to_query}").returns(resource2)
    
    RestClient::Resource.expects('new').with(options[:url], options[:options]).returns(resource)
  end
  
  def expect_post(options = {})
    response = mock('RestClient::Response')
    response.expects('net_http_res').returns(options[:returns].new 'x', 'x', 'x')
    
    resource = mock('RestClient::Resource')
    resource.expects('post').with(options[:data]).returns(response)
    
    RestClient::Resource.expects('new').with(options[:url], options[:options]).returns(resource)
  end
  
  def expect_no_rest
    RestClient::Resource.expects(:new).never
  end
    
  # Returns the string to be used for HTTP_AUTHENTICATION header
  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
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
  
  def assert_validates_configuration_presence_of(chan, field)
    chan.configuration.delete field
    assert !chan.save
  end
  
  def assert_handler_should_enqueue_ao_job(chan, job_class)
    chan.save!
    
    jobs = []
    Queues.expects(:publish_ao).with do |msg, job|
      jobs << job
    end
    
    msg = AOMessage.make :account_id => chan.account_id, :channel_id => chan.id
    chan.handler.handle(msg)
    
    assert_equal 1, jobs.length
    assert_equal job_class, jobs[0].class
    assert_equal msg.id, jobs[0].message_id
    assert_equal chan.id, jobs[0].channel_id
    assert_equal chan.account_id, jobs[0].account_id
    assert_equal msg.id, jobs[0].message_id
  end
end
