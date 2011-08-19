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

  test "apply custom attributes for AT messages" do
    account = Account.make
    CustomAttribute.create! :account => account, :address => 'sms://123', :custom_attributes => {'foo' => '1'}
    msg = AtMessage.make_unsaved :from => 'sms://123'
    channel = Channel.make

    account.route_at msg, channel

    assert_equal '1', msg.custom_attributes['foo']
  end

  test "custom attributes can be used to route AT" do
    account = Account.make
    channel = Channel.make :account => account
    app1 = Application.make :account => account
    app2 = Application.make :account => account
    CustomAttribute.create! :account => account, :address => 'sms://123', :custom_attributes => {'application' => app1.name}
    msg = AtMessage.make_unsaved :from => 'sms://123'

    account.route_at msg, channel

    assert_equal app1, msg.application
  end

end
