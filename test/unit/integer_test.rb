require 'test_helper'

class IntegerTest < ActiveSupport::TestCase
  test "as exponential backoff" do
    assert_equal 1, 1.as_exponential_backoff
    assert_equal 1, 2.as_exponential_backoff
    assert_equal 5, 3.as_exponential_backoff
    assert_equal 5, 4.as_exponential_backoff
    assert_equal 5, 5.as_exponential_backoff
    assert_equal 15, 6.as_exponential_backoff
    assert_equal 30, 7.as_exponential_backoff
    assert_equal 30, 1000.as_exponential_backoff
  end
end
