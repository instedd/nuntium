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

require 'test_helper'

class CustomAttributeTest < ActiveSupport::TestCase

  test "validate address presence" do
    ca = CustomAttribute.create
    assert ca.errors[:address]
  end

  test "deny duplicate custom attributes for same address" do
    account = Account.make!
    CustomAttribute.create! :account => account, :address => 'sms://123'
    assert_raise do
      CustomAttribute.create! :account => account, :address => 'sms://123'
    end
  end

  test "allow duplicate custom attributes for same address but different account" do
    CustomAttribute.create! :account => Account.make!, :address => 'sms://123'
    CustomAttribute.create! :account => Account.make!, :address => 'sms://123'
  end

  test "apply custom attributes for AT messages" do
    account = Account.make!
    CustomAttribute.create! :account => account, :address => 'sms://123', :custom_attributes => {'foo' => '1'}
    msg = AtMessage.make :from => 'sms://123'
    channel = QstServerChannel.make!

    account.route_at msg, channel

    assert_equal '1', msg.custom_attributes['foo']
  end

  test "custom attributes can be used to route AT" do
    account = Account.make!
    channel = QstServerChannel.make! :account => account
    app1 = Application.make! :account => account
    app2 = Application.make! :account => account
    CustomAttribute.create! :account => account, :address => 'sms://123', :custom_attributes => {'application' => app1.name}
    msg = AtMessage.make :from => 'sms://123'

    account.route_at msg, channel

    assert_equal app1, msg.application
  end

end
