require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "qst" do
    assert_routing({:path => "/some_account/qst/incoming", :method => :head }, { :controller => "incoming", :action => "index", :account_id => "some_account" })
    assert_routing({:path => "/some_account/qst/incoming", :method => :post }, { :controller => "incoming", :action => "create", :account_id => "some_account" })
    assert_routing({:path => "/some_account/qst/outgoing", :method => :get }, { :controller => "outgoing", :action => "index", :account_id => "some_account" })

    ["new", "create"].each do |op|
      assert_routing({:path => "/channel/#{op}/qst_server"}, { :controller => "channel", :action => "#{op}_channel", :kind => 'qst_server' })
    end
  end

  test "accounts" do
    ["create_account", "login", "logoff"].each do |path|
      assert_routing({:path => "/" + path}, { :controller => "home", :action => path })
    end
    ["update"].each do |op|
      assert_routing({:path => "/account/#{op}"}, { :controller => "home", :action => "#{op}_account"})
    end
  end

  test "channels" do
    ["edit", "update", "delete", "enable", "disable", "pause", "resume"].each do |op|
      assert_routing({:path => "/channel/#{op}/10"}, { :controller => "channel", :action => "#{op}_channel", :id => '10' })
    end
  end

  test "twitter" do
    assert_routing({:path => "/channel/create/twitter"}, { :controller => "twitter", :action => "create_twitter_channel", :kind => "twitter" })
    assert_routing({:path => "/channel/update/twitter"}, { :controller => "twitter", :action => "update_twitter_channel" })
    assert_routing({:path => "/twitter_callback"}, { :controller => "twitter", :action => "twitter_callback" })
  end

  test "home" do
    ['interactions', 'settings', 'applications', 'channels', 'ao_messages', 'at_messages', 'logs'].each do |name|
      assert_routing({:path => "/#{name}"}, { :controller => "home", :action => name })
    end
  end

  test "messages" do
    ["ao", "at"].each do |kind|
      ["new", "create"].each do |op|
        assert_routing({:path => "/message/#{kind}/#{op}"}, { :controller => "message", :action => "#{op}_#{kind}_message" })
      end
      assert_routing({:path => "/message/#{kind}/mark_as_cancelled"}, { :controller => "message", :action => "mark_#{kind}_messages_as_cancelled" })
      assert_routing({:path => "/message/#{kind}/10"}, { :controller => "message", :action => "view_#{kind}_message", :id => '10' })
      assert_routing({:path => "/message/#{kind}/simulate_route"}, { :controller => "message", :action => "simulate_route_#{kind}" })
    end
    assert_routing({:path => "/message/ao/reroute"}, { :controller => "message", :action => "reroute_ao_messages" })
  end

  test "applications" do
    ['new', 'create'].each do |action|
      assert_routing({:path => "/application/#{action}"}, { :controller => "home", :action => "#{action}_application" })
    end
    ['edit', 'update', 'delete'].each do |action|
      assert_routing({:path => "/application/#{action}/10"}, { :controller => "home", :action => "#{action}_application", :id => '10' })
    end
  end

  test "interfaces" do
    assert_routing({:path => "/account/app/rss", :method => :get }, { :controller => "rss", :action => "index", :account_name => 'account', :application_name => 'app' })
    assert_routing({:path => "/account/app/rss", :method => :post }, { :controller => "rss", :action => "create", :account_name => 'account', :application_name => 'app' })
    assert_routing({:path => "/account/app/send_ao"}, { :controller => "send_ao", :action => "create", :account_name => 'account', :application_name => 'app' })
  end

  test "clickatell" do
    assert_routing({:path => "/clickatell/view_credit"}, { :controller => "clickatell", :action => "view_credit" })
    assert_routing({:path => "/some_account/clickatell/incoming"}, { :controller => "clickatell", :action => "index", :account_id => "some_account" })
    assert_routing({:path => "/some_account/clickatell/ack"}, { :controller => "clickatell", :action => "ack", :account_id => "some_account" })
  end

  test "dtac" do
    assert_routing({:path => "/some_account/dtac/incoming"}, { :controller => "dtac", :action => "index", :account_id => "some_account" })
  end

  test "api" do
    assert_routing({:path => "/api/countries.xml"}, { :controller => "api_country", :action => "index", :format => "xml" })
    assert_routing({:path => "/api/countries/foo.xml"}, { :controller => "api_country", :action => "show", :format => "xml", :iso => 'foo'})
    assert_routing({:path => "/api/carriers.xml"}, { :controller => "api_carrier", :action => "index", :format => "xml" })
    assert_routing({:path => "/api/carriers/foo.xml"}, { :controller => "api_carrier", :action => "show", :format => "xml", :guid => 'foo' })
    assert_routing({:path => "/api/channels.xml", :method => :get}, { :controller => "api_channel", :action => "index", :format => "xml" })
    assert_routing({:path => "/api/channels/foo.xml", :method => :get}, { :controller => "api_channel", :action => "show", :format => "xml", :name => "foo" })
    assert_routing({:path => "/api/channels.xml", :method => :post}, { :controller => "api_channel", :action => "create", :format => "xml" })
    assert_routing({:path => "/api/channels/foo.xml", :method => :put}, { :controller => "api_channel", :action => "update", :format => "xml", :name => "foo" })
    assert_routing({:path => "/api/channels/foo", :method => :delete}, { :controller => "api_channel", :action => "destroy", :name => "foo" })
    assert_routing({:path => "/api/candidate/channels.xml", :method => :get}, { :controller => "api_channel", :action => "candidates", :format => "xml" })
    assert_routing({:path => "/api/channels/foo/twitter/friendships/create", :method => :get}, { :controller => "api_twitter_channel", :action => "friendship_create", :name => "foo" })
  end
end
