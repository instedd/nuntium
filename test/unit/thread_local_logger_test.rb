require 'test_helper'

class ThreadLocalLoggerTest < ActiveSupport::TestCase
  test "appends one line" do
    ThreadLocalLogger.reset
    ThreadLocalLogger << "Hello!"
    assert_equal "Hello!", ThreadLocalLogger.result
  end

  test "appends two lines" do
    ThreadLocalLogger.reset
    ThreadLocalLogger << "Hello!"
    ThreadLocalLogger << "Bye!"
    assert_equal "Hello!\nBye!", ThreadLocalLogger.result
  end

  test "reset" do
    ThreadLocalLogger.reset
    ThreadLocalLogger << "Hello!"
    ThreadLocalLogger.reset

    assert_equal "", ThreadLocalLogger.result
  end

  test "destroy" do
    ThreadLocalLogger.reset
    ThreadLocalLogger << "Hello!"
    ThreadLocalLogger.destroy

    assert_equal nil, ThreadLocalLogger.result
  end

  test "don't append if not available" do
    ThreadLocalLogger.destroy
    ThreadLocalLogger << "Hello!"
    assert_equal nil, ThreadLocalLogger.result
  end
end
