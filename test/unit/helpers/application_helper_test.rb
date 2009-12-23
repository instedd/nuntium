require 'test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper

  test "short for nil" do
    assert_equal '', short(nil)
  end
  
  test "short for short string" do
    assert_equal 'hello', short('hello', 8)
  end
  
  test "short for long string" do
    assert_equal 'hello wo...', short('hello world', 8)
  end
end