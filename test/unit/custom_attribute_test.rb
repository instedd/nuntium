require 'test_helper'

class CustomAttributeTest < ActiveSupport::TestCase

  test "validate address presence" do
    ca = CustomAttribute.create
    assert ca.errors[:address]
  end

  test "deny duplicate custom attributes for same address" do
    account = Account.make
    CustomAttribute.create! :account => account, :address => 'sms://123'
    assert_raise do
      CustomAttribute.create! :account => account, :address => 'sms://123'
    end
  end

  test "allow duplicate custom attributes for same address but different account" do
    CustomAttribute.create! :account => Account.make, :address => 'sms://123'
    CustomAttribute.create! :account => Account.make, :address => 'sms://123'
  end

end
