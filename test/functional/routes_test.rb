require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "qst" do
    assert_routing({:path => "/some_account/qst/incoming", :method => :get }, { :controller => "qst_server", :action => "get_last_id", :account_id => "some_account" })
    assert_routing({:path => "/some_account/qst/incoming", :method => :post }, { :controller => "qst_server", :action => "push", :account_id => "some_account" })
    assert_routing({:path => "/some_account/qst/outgoing", :method => :get }, { :controller => "qst_server", :action => "pull", :account_id => "some_account" })
    assert_routing({:path => "/some_account/qst/setaddress", :method => :post}, { :controller => "qst_server", :action => "set_address", :account_id => "some_account"})
    assert_generates("/some_account/qst/setaddress", { :controller => "qst_server", :action => "set_address", :account_id => "some_account"})
  end

  test "twitter" do
    assert_routing({:path => "/twitter/callback"}, { :controller => "twitter", :action => "callback" })
    assert_routing({:path => "/twitter/view_rate_limit_status"}, { :controller => "twitter", :action => "view_rate_limit_status" })
  end

  test "interfaces" do
    assert_routing({:path => "/account/app/rss", :method => :get }, { :controller => "rss", :action => "index", :account_name => 'account', :application_name => 'app', :format => 'xml' })
    assert_routing({:path => "/account/app/rss", :method => :post }, { :controller => "rss", :action => "create", :account_name => 'account', :application_name => 'app' })
    assert_routing({:path => "/account/app/send_ao"}, { :controller => "ao_messages", :action => "create_via_api", :account_name => 'account', :application_name => 'app' })
    assert_routing({:path => "/account/app/get_ao"}, { :controller => "ao_messages", :action => "get_ao", :account_name => 'account', :application_name => 'app' })
  end

  test "clickatell" do
    assert_routing({:path => "/clickatell/view_credit"}, { :controller => "clickatell", :action => "view_credit" })
    assert_routing({:path => "/some_account/clickatell/incoming"}, { :controller => "clickatell", :action => "index", :account_id => "some_account" })
    assert_routing({:path => "/some_account/clickatell/ack"}, { :controller => "clickatell", :action => "ack", :account_id => "some_account" })
  end

  test "dtac" do
    assert_routing({:path => "/some_account/dtac/incoming"}, { :controller => "dtac", :action => "index", :account_id => "some_account" })
  end

  test "ipop" do
    assert_routing({:path => "/some_account/ipop/some_channel/incoming", :method => :post}, { :controller => "ipop", :action => "index", :account_id => "some_account", :channel_name => "some_channel"})
    assert_routing({:path => "/some_account/ipop/some_channel/ack", :method => :post}, { :controller => "ipop", :action => "ack", :account_id => "some_account", :channel_name => "some_channel"})
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
    assert_routing({:path => "/api/custom_attributes", :method => :get}, { :controller => "api_custom_attributes", :action => "show" })
    assert_routing({:path => "/api/custom_attributes", :method => :post}, { :controller => "api_custom_attributes", :action => "create_or_update" })
  end
end
