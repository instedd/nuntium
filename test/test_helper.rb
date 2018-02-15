# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/blueprints")
require 'rails/test_help'
require 'base64'
require 'digest/md5'
require 'digest/sha2'
require 'shoulda'
require 'mocha'

require File.expand_path(File.dirname(__FILE__) + "/unit/generic_channel_test")
require File.expand_path(File.dirname(__FILE__) + "/unit/service_channel_test")

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

  ActiveRecord::Migration.check_pending!

  include Mocha::API

  setup do
    Rails.cache.clear
    Country.clear_cache
    Carrier.clear_cache
    Sham.reset
  end

  def expect_get(options = {})
    resource2 = mock('RestClient::Resource')

    query_params = options[:query_params]
    query_params = query_params.to_query if query_params.kind_of? Hash

    if options[:returns] == Net::HTTPBadRequest
      resource2.expects('get').raises RestClient::BadRequest
    else
      response = mock('RestClient::Response')
      response.expects('net_http_res').returns(options[:returns].new 'x', 'x', 'x')
      response.stubs(:body => options[:returns_body])

      resource2.expects('get').returns(response)
    end

    resource = mock('RestClient::Resource')
    resource.expects('[]').with("?#{query_params}").returns(resource2)

    RestClient::Resource.expects('new').with(options[:url], options[:options]).returns(resource)
  end

  def expect_post(options = {})
    resource = mock('RestClient::Resource')

    if options[:returns] == Net::HTTPBadRequest
      resource.expects('post').raises RestClient::BadRequest
    else
      ret = options[:returns].new 'x', 'x', 'x'

      response = mock('RestClient::Response')
      response.expects('net_http_res').returns(ret)
      response.stubs(:body => options[:returns_body])
      ret.stubs(:content_type => options[:returns_content_type])

      resource.expects('post').with(options[:data]).returns(response)
    end

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

  # Creates an AtMessage that belongs to account and has values according to i
  def new_at_message(application, i, channel = nil)
    msg = new_message application.account, i, AtMessage
    msg.channel = channel if channel
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

  def assert_channel_should_enqueue_ao_job(chan)
    chan.save!

    jobs = []
    Queues.expects(:publish_ao).with do |msg, job|
      jobs << job
    end

    msg = AoMessage.make :account_id => chan.account_id, :channel_id => chan.id
    chan.handle(msg)

    assert_equal 1, jobs.length
    assert_equal chan.job_class, jobs[0].class
    assert_equal msg.id, jobs[0].message_id
    assert_equal chan.id, jobs[0].channel_id
    assert_equal chan.account_id, jobs[0].account_id
    assert_equal msg.id, jobs[0].message_id
  end

  def assert_can_leave_password_empty(chan, field = :password)
    old_password = chan.send(field)

    chan.send "#{field}=", ''
    chan.save!

    chan.reload

    assert_equal old_password, chan.send(field)
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end
