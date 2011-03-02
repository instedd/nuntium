require 'test_helper'

class ATMessageTest < ActiveSupport::TestCase
  test "at rules context include common fiels and custom attributes" do
    msg = ATMessage.make_unsaved
    msg.custom_attributes = { "ca1" => 'e', "ca2" => 'f' }

    context = msg.rules_context

    ['from', 'to', 'subject', 'body'].each do |field|
      assert_equal msg.send(field), context[field]
    end
    assert_equal 'e', context["ca1"]
    assert_equal 'f', context["ca2"]
  end

  test "merge attributes recognize wellknown fields and custom attributes" do
    msg = ATMessage.new
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
    country = Country.make

    msg = ATMessage.new :from => "sms://+#{country.phone_prefix}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_nil msg.carrier
  end

  test "fix mobile number" do
    msg = ATMessage.new :from => 'sms://+1234', :to => 'sms://+5678'
    assert_equal 'sms://1234', msg.from
    assert_equal 'sms://5678', msg.to

    msg = ATMessage.new :from => 'xmpp://+1234', :to => 'xmpp://+5678'
    assert_equal 'xmpp://+1234', msg.from
    assert_equal 'xmpp://+5678', msg.to
  end
end
