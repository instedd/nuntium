require 'test_helper'

class AOMessageTest < ActiveSupport::TestCase
  test "subject and body no subject nor body" do
    msg = AOMessage.new
    assert_equal '', msg.subject_and_body
  end

  test "subject and body just subject" do
    msg = AOMessage.new :subject => 'subject'
    assert_equal 'subject', msg.subject_and_body
  end

  test "subject and body just body" do
    msg = AOMessage.new :body => 'body'
    assert_equal 'body', msg.subject_and_body
  end

  test "subject and body" do
    msg = AOMessage.new :subject => 'subject', :body => 'body'
    assert_equal 'subject - body', msg.subject_and_body
  end

  test "infer attributes none" do
    msg = AOMessage.new :to => 'sms://+1234'
    msg.infer_custom_attributes

    assert_nil msg.country
    assert_nil msg.carrier
  end

  test "infer attributes when to is just protocol" do
    msg = AOMessage.new :to => 'sms://'
    msg.infer_custom_attributes

    assert_nil msg.country
    assert_nil msg.carrier
  end

  test "infer attributes one country" do
    country = Country.make

    msg = AOMessage.new :to => "sms://+#{country.phone_prefix}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_nil msg.carrier
  end

  test "infer attributes two countries" do
    one = Country.make :phone_prefix => '12'
    two = Country.make :phone_prefix => '1'
    three = Country.make :phone_prefix => '2'

    msg = AOMessage.new :to => 'sms://+1234'
    msg.infer_custom_attributes

    assert_equal [one.iso2, two.iso2], msg.country
    assert_nil msg.carrier
  end

  test "infer country from area code" do
    usa = Country.make :phone_prefix => '1'
    canada = Country.make :phone_prefix => '1', :area_codes => '250, 204'

    msg = AOMessage.new :to => 'sms://+12501345'
    msg.infer_custom_attributes
    assert_equal canada.iso2, msg.country

    msg = AOMessage.new :to => 'sms://+1234567'
    msg.infer_custom_attributes
    assert_equal usa.iso2, msg.country
  end

  test "infer many countries because of lack of area code" do
    usa = Country.make :phone_prefix => '1'
    usa2 = Country.make :phone_prefix => '1'
    canada = Country.make :phone_prefix => '1', :area_codes => '250, 204'

    msg = AOMessage.new :to => 'sms://+1234567'
    msg.infer_custom_attributes
    assert_equal [usa.iso2, usa2.iso2], msg.country
  end

  test "don't infer country if already specified" do
    country = Country.make :iso2 => 'ar'

    msg = AOMessage.new :to => 'sms://+#{country.phone_prefix}1234'
    msg.country = 'br'
    msg.infer_custom_attributes

    assert_equal 'br', msg.country
    assert_nil msg.carrier
  end

  test "infer attributes one carrier" do
    country = Country.make
    carrier = Carrier.make :country => country

    msg = AOMessage.new :to => "sms://+#{country.phone_prefix}#{carrier.prefixes}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "infer attributes two carriers" do
    country = Country.make :phone_prefix => '12'
    c1 = Carrier.make :country => country, :prefixes => '34, 56'
    c2 = Carrier.make :country => country, :prefixes => '3'
    c3 = Carrier.make :country => country, :prefixes => '4'

    msg = AOMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal Set.new([c1.guid, c2.guid]), Set.new(msg.carrier)
  end

  test "don't infer carrier if present" do
    country = Country.make :iso2 => 'ar'
    carrier = Carrier.make :country => country, :guid => 'personal'

    msg = AOMessage.new(:to => 'sms://+#{country.phone_prefix}#{carrier.prefixes}1234')
    msg.country = country.iso2
    msg.carrier = 'movistar'
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal 'movistar', msg.carrier
  end

  test "infer from mobile numbers" do
    country = Country.make :iso2 => 'ar', :phone_prefix => '0'
    carrier = Carrier.make :country => country, :guid => 'personal'
    mob = MobileNumber.create! :number => '1234', :country => country, :carrier => carrier

    msg = AOMessage.new :to => 'sms://1234'
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "infer partially from mobile numbers" do
    country = Country.make :iso2 => 'ar', :phone_prefix => '0'
    carrier = Carrier.make :country => country, :guid => 'personal'
    mob = MobileNumber.create! :number => '1234', :carrier => carrier

    msg = AOMessage.new :to => 'sms://1234'
    msg.country = 'ar'
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  ['failed', 'confirmed', 'delivered'].each do |state|
    test "delivery ack when #{state}" do
      account = Account.make
      app = Application.make_unsaved :account => account
      app.delivery_ack_method = 'get'
      app.delivery_ack_url = 'foo'
      app.save!
      chan = Channel.make :account => account

      msg = AOMessage.make :account => account, :application => app, :channel => chan

      Queues.expects(:publish_application).with do |a, j|
        a.id == app.id and
          j.kind_of?(SendDeliveryAckJob) and
          j.account_id == account.id and
          j.application_id == app.id and
          j.message_id == msg.id and
          j.state == state
      end

      msg.state = state
      msg.save!
    end
  end

  test "don't delivery ack when queued" do
    account = Account.make
    app = Application.make_unsaved :account => account
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = Channel.make :account => account

    msg = AOMessage.make :account => account, :application => app, :channel => chan

    Queues.expects(:publish_application).times(0)

    msg.state = 'queued'
    msg.save!
  end

  test "don't delivery ack when method is none" do
    account = Account.make
    app = Application.make_unsaved :account => account
    app.delivery_ack_method = 'none'
    app.save!
    chan = Channel.make :account => account

    msg = AOMessage.make :account => account, :application => app, :channel => chan

    Queues.expects(:publish_application).times(0)

    msg.state = 'failed'
    msg.save!
  end

  test "don't delivery ack when channel is not set" do
    account = Account.make
    app = Application.make_unsaved :account => account
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = Channel.make :account => account

    msg = AOMessage.make :account => account, :application => app

    Queues.expects(:publish_application).times(0)

    msg.state = 'failed'
    msg.save!
  end

  test "delivery ack when changed" do
    account = Account.make
    app = Application.make_unsaved :account => account
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = Channel.make :account => account

    Queues.expects(:publish_application).times(2)

    msg = AOMessage.make :account => account, :application => app, :channel => chan, :state => 'delivered'

    msg.custom_attributes[:cost] = '1'
    msg.save!
  end

  test "don't delivery ack when not changed" do
    account = Account.make
    app = Application.make_unsaved :account => account
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = Channel.make :account => account

    Queues.expects(:publish_application).times(1)

    msg = AOMessage.make :account => account, :application => app, :channel => chan, :state => 'delivered'

    msg.save!
  end
end
