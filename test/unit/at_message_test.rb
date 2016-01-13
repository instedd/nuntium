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

class AtMessageTest < ActiveSupport::TestCase
  test "at rules context include common fiels and custom attributes" do
    msg = AtMessage.make
    msg.custom_attributes = { "ca1" => 'e', "ca2" => 'f' }

    context = msg.rules_context

    ['from', 'to', 'subject', 'body'].each do |field|
      assert_equal msg.send(field), context[field]
    end
    assert_equal 'e', context["ca1"]
    assert_equal 'f', context["ca2"]
  end

  test "merge attributes recognize wellknown fields and custom attributes" do
    msg = AtMessage.new
    attributes = { "from" => 'a', "to" => 'b', "subject" => 'c', "body" => 'd', "ca1" => 'e', "ca2" => 'f' }

    msg.merge attributes

    assert_equal 'a', msg.from
    assert_equal 'b', msg.to
    assert_equal 'c', msg.subject
    assert_equal 'd', msg.body
    assert_equal 'e', msg.custom_attributes["ca1"]
    assert_equal 'f', msg.custom_attributes["ca2"]
  end

  test "infer attributes one country" do
    country = Country.make!

    msg = AtMessage.new :from => "sms://+#{country.phone_prefix}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_nil msg.carrier
  end

  test "fix mobile number" do
    msg = AtMessage.new :from => 'sms://+1234', :to => 'sms://+5678'
    assert_equal 'sms://1234', msg.from
    assert_equal 'sms://5678', msg.to

    msg = AtMessage.new :from => 'xmpp://+1234', :to => 'xmpp://+5678'
    assert_equal 'xmpp://+1234', msg.from
    assert_equal 'xmpp://+5678', msg.to
  end

  test "should update application lifespan when created" do
    application = Application.make!
    account = Account.make!
    at_message = AtMessage.make application: application, account: account

    Telemetry::Lifespan.expects(:touch_application).with(application)

    at_message.save
  end

  test "should update application lifespan when updated" do
    application = Application.make!
    account = Account.make!
    at_message = AtMessage.make! application: application, account: account

    Telemetry::Lifespan.expects(:touch_application).with(application)

    at_message.touch
    at_message.save
  end

  test "should update application lifespan when destroyed" do
    application = Application.make!
    account = Account.make!
    at_message = AtMessage.make! application: application, account: account

    Telemetry::Lifespan.expects(:touch_application).with(application)

    at_message.destroy
  end

  test "should update account lifespan when created" do
    account = Account.make!
    at_message = AtMessage.make account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    at_message.save
  end

  test "should update account lifespan when updated" do
    account = Account.make!
    at_message = AtMessage.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    at_message.touch
    at_message.save
  end

  test "should update account lifespan when destroyed" do
    account = Account.make!
    at_message = AtMessage.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    at_message.destroy
  end
end
