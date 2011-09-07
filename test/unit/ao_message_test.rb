require 'test_helper'

class AoMessageTest < ActiveSupport::TestCase
  test "subject and body no subject nor body" do
    msg = AoMessage.new
    assert_equal '', msg.subject_and_body
  end

  test "subject and body just subject" do
    msg = AoMessage.new :subject => 'subject'
    assert_equal 'subject', msg.subject_and_body
  end

  test "subject and body just body" do
    msg = AoMessage.new :body => 'body'
    assert_equal 'body', msg.subject_and_body
  end

  test "subject and body" do
    msg = AoMessage.new :subject => 'subject', :body => 'body'
    assert_equal 'subject - body', msg.subject_and_body
  end

  test "infer attributes none" do
    msg = AoMessage.new :to => 'sms://+1234'
    msg.infer_custom_attributes

    assert_nil msg.country
    assert_nil msg.carrier
  end

  test "infer attributes when to is just protocol" do
    msg = AoMessage.new :to => 'sms://'
    msg.infer_custom_attributes

    assert_nil msg.country
    assert_nil msg.carrier
  end

  test "infer attributes one country" do
    country = Country.make

    msg = AoMessage.new :to => "sms://+#{country.phone_prefix}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_nil msg.carrier
  end

  test "infer attributes two countries" do
    one = Country.make :phone_prefix => '12'
    two = Country.make :phone_prefix => '1'
    three = Country.make :phone_prefix => '2'

    msg = AoMessage.new :to => 'sms://+1234'
    msg.infer_custom_attributes

    assert_equal [one.iso2, two.iso2], msg.country
    assert_nil msg.carrier
  end

  test "infer country from area code" do
    usa = Country.make :phone_prefix => '1'
    canada = Country.make :phone_prefix => '1', :area_codes => '250, 204'

    msg = AoMessage.new :to => 'sms://+12501345'
    msg.infer_custom_attributes
    assert_equal canada.iso2, msg.country

    msg = AoMessage.new :to => 'sms://+1234567'
    msg.infer_custom_attributes
    assert_equal usa.iso2, msg.country
  end

  test "infer many countries because of lack of area code" do
    usa = Country.make :phone_prefix => '1'
    usa2 = Country.make :phone_prefix => '1'
    canada = Country.make :phone_prefix => '1', :area_codes => '250, 204'

    msg = AoMessage.new :to => 'sms://+1234567'
    msg.infer_custom_attributes
    assert_equal [usa.iso2, usa2.iso2], msg.country
  end

  test "don't infer country if already specified" do
    country = Country.make :iso2 => 'ar'

    msg = AoMessage.new :to => 'sms://+#{country.phone_prefix}1234'
    msg.country = 'br'
    msg.infer_custom_attributes

    assert_equal 'br', msg.country
    assert_nil msg.carrier
  end

  test "infer attributes one carrier" do
    country = Country.make
    carrier = Carrier.make :country => country

    msg = AoMessage.new :to => "sms://+#{country.phone_prefix}#{carrier.prefixes}1234"
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "infer attributes two carriers" do
    country = Country.make :phone_prefix => '12'
    c1 = Carrier.make :country => country, :prefixes => '34, 56'
    c2 = Carrier.make :country => country, :prefixes => '3'
    c3 = Carrier.make :country => country, :prefixes => '4'

    msg = AoMessage.new(:to => 'sms://+1234')
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal Set.new([c1.guid, c2.guid]), Set.new(msg.carrier)
  end

  test "don't infer carrier if present" do
    country = Country.make :iso2 => 'ar'
    carrier = Carrier.make :country => country, :guid => 'personal'

    msg = AoMessage.new(:to => 'sms://+#{country.phone_prefix}#{carrier.prefixes}1234')
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

    msg = AoMessage.new :to => 'sms://1234'
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "infer partially from mobile numbers" do
    country = Country.make :iso2 => 'ar', :phone_prefix => '0'
    carrier = Carrier.make :country => country, :guid => 'personal'
    mob = MobileNumber.create! :number => '1234', :carrier => carrier

    msg = AoMessage.new :to => 'sms://1234'
    msg.country = 'ar'
    msg.infer_custom_attributes

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  ['failed', 'confirmed', 'delivered'].each do |state|
    test "delivery ack when #{state}" do
      account = Account.make
      app = account.applications.make_unsaved
      app.delivery_ack_method = 'get'
      app.delivery_ack_url = 'foo'
      app.save!
      chan = QstServerChannel.make :account_id => account.id

      msg = account.ao_messages.make :application => app, :channel => chan

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
    app = account.applications.make_unsaved
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = QstServerChannel.make :account_id => account.id

    msg = account.ao_messages.make :application => app, :channel => chan

    Queues.expects(:publish_application).times(0)

    msg.state = 'queued'
    msg.save!
  end

  test "don't delivery ack when method is none" do
    account = Account.make
    app = account.applications.make_unsaved
    app.delivery_ack_method = 'none'
    app.save!
    chan = QstServerChannel.make :account_id => account.id

    msg = account.ao_messages.make :application => app, :channel => chan

    Queues.expects(:publish_application).times(0)

    msg.state = 'failed'
    msg.save!
  end

  test "don't delivery ack when channel is not set" do
    account = Account.make
    app = account.applications.make_unsaved
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = QstServerChannel.make :account_id => account.id

    msg = account.ao_messages.make :application => app

    Queues.expects(:publish_application).times(0)

    msg.state = 'failed'
    msg.save!
  end

  test "delivery ack when changed" do
    account = Account.make
    app = account.applications.make_unsaved
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = QstServerChannel.make :account_id => account.id

    Queues.expects(:publish_application).times(2)

    msg = account.ao_messages.make :application => app, :channel => chan, :state => 'delivered'

    msg.custom_attributes[:cost] = '1'
    msg.save!
  end

  test "don't delivery ack when not changed" do
    account = Account.make
    app = account.applications.make_unsaved
    app.delivery_ack_method = 'get'
    app.delivery_ack_url = 'foo'
    app.save!
    chan = QstServerChannel.make :account_id => account.id

    Queues.expects(:publish_application).times(1)

    msg = account.ao_messages.make :application => app, :channel => chan, :state => 'delivered'

    msg.save!
  end

  test "fix mobile number" do
    msg = AoMessage.new :from => 'sms://+1234', :to => 'sms://+5678'
    assert_equal 'sms://1234', msg.from
    assert_equal 'sms://5678', msg.to

    msg = AoMessage.new :from => 'xmpp://+1234', :to => 'xmpp://+5678'
    assert_equal 'xmpp://+1234', msg.from
    assert_equal 'xmpp://+5678', msg.to
  end

  test "setting timestamp in future sets it to current time" do
    time = Time.now + 10.days

    msg = AoMessage.new
    msg.timestamp = time
    assert_not_equal time, msg.timestamp
    assert (Time.now - msg.timestamp).abs < 3.seconds
  end

  test "setting timestamp in past leaves it like that" do
    time = Time.now - 10.days

    msg = AoMessage.new
    msg.timestamp = time
    assert_equal time, msg.timestamp
  end
end
