require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "get /rss" do
    assert_routing({ :path => "/rss", :method => :get }, { :controller => "rss", :action => "index" })
  end
  
  test "post /rss" do
    assert_routing({ :path => "/rss", :method => :post }, { :controller => "rss", :action => "create" })
  end
  
  test "head /qst/incoming" do
    assert_routing({ :path => "/qst/incoming", :method => :head }, { :controller => "incoming", :action => "index" })
  end
  
  test "post /qst/incoming" do
    assert_routing({ :path => "/qst/incoming", :method => :post }, { :controller => "incoming", :action => "create" })
  end
  
  test "get /qst/outgoing" do
    assert_routing({ :path => "/qst/outgoing", :method => :get }, { :controller => "outgoing", :action => "index" })
  end
end