require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "get /rss" do
    assert_routing({ :path => "/rss", :method => :get }, { :controller => "rss", :action => "index" })
  end
  
  test "post /rss" do
    assert_routing({ :path => "/rss", :method => :post }, { :controller => "rss", :action => "create" })
  end
  
  test "head /qst/application_id/incoming" do
    assert_routing({ :path => "/qst/some_app/incoming", :method => :head }, { :controller => "incoming", :action => "index", :application_id => "some_app" })
  end
  
  test "post /qst/application_id/incoming" do
    assert_routing({ :path => "/qst/some_app/incoming", :method => :post }, { :controller => "incoming", :action => "create", :application_id => "some_app" })
  end
  
  test "get /qst/application_id/outgoing" do
    assert_routing({ :path => "/qst/some_app/outgoing", :method => :get }, { :controller => "outgoing", :action => "index", :application_id => "some_app" })
  end
end