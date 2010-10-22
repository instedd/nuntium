require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase

  test "check modified" do
    app = Application.make
    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority - 10

    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'
    assert_equal chan2.id, msg.channel_id

    chan2.priority = chan1.priority + 10
    chan2.save!

    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'
    assert_equal chan1.id, msg.channel_id
  end

  test "should create worker queue on create" do
    app = Application.make
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal "application_queue.#{app.id}", wqs[0].queue_name
    assert_equal "fast", wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end

  test "should bind queue on create" do
    binded = nil

    Queues.expects(:bind_application).with do |a|
      binded = a
      true
    end

    app = Application.make
    assert_same app, binded
  end

  test "should enqueue http post callback" do
    app = Application.make :http_post_callback

    msg = ATMessage.create!(:account => app.account, :subject => 'foo')

    Queues.expects(:publish_application).with do |a, j|
      a.id == app.id and
        j.kind_of?(SendPostCallbackMessageJob) and
        j.account_id == app.account.id and
        j.application_id == app.id and
        j.message_id == msg.id
    end

    app.route_at msg, (Channel.make :account_id => app.account_id)
  end

  test "route ao protocol not found in message" do
    app = Application.make

    msg = AOMessage.make_unsaved :to => '+5678'
    app.route_ao msg, 'test'

    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  end

  test "route ao channel not found for protocol" do
    app = Application.make

    msg = AOMessage.make_unsaved :to => 'unknown://+5678'
    app.route_ao msg, 'test'

    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  end

  test "route select channel based on protocol" do
    app = Application.make

    chan1 = Channel.make :account => app.account, :protocol => 'protocol'
    chan2 = Channel.make :account => app.account, :protocol => 'protocol2'

    msg = AOMessage.make_unsaved(:to => 'protocol2://Someone else')
    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "candidate channels" do
    app = Application.make

    chan1 = Channel.make :account => app.account, :protocol => 'protocol'
    chan2 = Channel.make :account => app.account, :protocol => 'protocol2'

    msg = AOMessage.make_unsaved(:to => 'protocol2://Someone else')
    channels = app.candidate_channels_for_ao msg

    assert_equal [chan2], channels
  end

  test "candidate channels ordered by priority" do
    app = Application.make

    chan1 = Channel.make :account => app.account, :protocol => 'protocol', :priority => 2
    chan2 = Channel.make :account => app.account, :protocol => 'protocol', :priority => 1

    msg = AOMessage.make_unsaved(:to => 'protocol://Someone else')
    channels = app.candidate_channels_for_ao msg

    assert_equal [chan2.id, chan1.id], channels.map(&:id)
  end

  test "route ao saves mobile numbers" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country

    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid

    app.route_ao msg, 'test'

    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.to.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end

  test "route ao does not save mobile numbers if more than one country and/or carrier" do
    app = Application.make

    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']

    app.route_ao msg, 'test'

    assert_equal 0, MobileNumber.count
  end

  test "route ao updates mobile numbers" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country

    MobileNumber.create!(:number => '5678', :country_id => country.id + 1)

    msg = AOMessage.make_unsaved :to => 'sms://+5678'
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid

    app.route_ao msg, 'test'

    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.to.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end

  test "route ao completes country and carrier if missing" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country
    MobileNumber.create!(:number => '5678', :country_id => country.id, :carrier_id => carrier.id)

    msg = AOMessage.make_unsaved :to => 'sms://+5678'

    app.route_ao msg, 'test'

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "route ao doesnt complete country or carrier if present" do
    app = Application.make
    country = Country.make
    carrier = Carrier.make :country => country
    MobileNumber.create!(:number => '5678', :country_id => country.id, :carrier_id => carrier.id)

    msg = AOMessage.make_unsaved :to => 'sms://+5678', :country => 'foo_country', :carrier => 'foo_carrier'

    app.route_ao msg, 'test'

    assert_equal 'foo_country', msg.country
    assert_equal 'foo_carrier', msg.carrier
  end

  test "route ao doesnt complete country or carrier if mobile number is missing" do
    app = Application.make

    msg = AOMessage.make_unsaved :to => 'sms://+5678'

    app.route_ao msg, 'test'

    assert_equal nil, msg.country
    assert_equal nil, msg.carrier
  end

  test "route ao filter channel because of country" do
    app = Application.make

    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = 'br'

    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = 'ar'
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'failed', msg.state
  end

  test "route ao filter channel because of country 2" do
    app = Application.make

    msg = AOMessage.make_unsaved
    msg.custom_attributes['country'] = ['br', 'bz']

    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = ['ar', 'br']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
  end

  test "route ao test filter when empty value passes" do
    app = Application.make

    msg = AOMessage.make_unsaved

    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = ['ar', '']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
  end

  test "route ao test filter when empty value does not pass" do
    app = Application.make

    msg = AOMessage.make_unsaved

    chan1 = Channel.make_unsaved :account => app.account
    chan1.restrictions['country'] = ['ar']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'failed', msg.state
  end

  test "route ao use last channel" do
    app = Application.make

    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10

    msg = AOMessage.make_unsaved :to => 'sms://+5678'

    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan2.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "route ao use last recent channel" do
    app = Application.make

    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10
    chan3 = Channel.make :account => app.account, :priority => chan1.priority + 20

    msg = AOMessage.make_unsaved :to => 'sms://+5678'

    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan1.id, :address => msg.to, :updated_at => (Time.now - 10)
    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan3.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan3.id, msg.channel_id
  end

  test "route ao use last recent channel that is a candidate" do
    app = Application.make

    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10
    chan3 = Channel.make :account => app.account, :priority => chan1.priority + 20, :enabled => false

    msg = AOMessage.make_unsaved :to => 'sms://+5678'

    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan1.id, :address => msg.to, :updated_at => (Time.now - 10)
    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan3.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan1.id, msg.channel_id
  end

  test "route ao use suggested channel" do
    app = Application.make
    chan1 = Channel.make :account => app.account
    chan2 = Channel.make :account => app.account, :priority => chan1.priority + 10

    msg = AOMessage.make_unsaved
    msg.suggested_channel = chan2.name
    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "route ao infer country" do
    app = Application.make
    chan = Channel.make :account => app.account
    country = Country.make

    msg = AOMessage.make_unsaved :to => "sms://+#{country.phone_prefix}1234"
    app.route_ao msg, 'test'

    assert_equal country.iso2, msg.country
  end

  test "route ao broadcast" do
    app = Application.make :broadcast

    chans = [Channel.make(:account => app.account), Channel.make(:account => app.account)]

    msg = AOMessage.make_unsaved
    app.route_ao msg, 'test'

    assert_nil msg.channel
    assert_equal 'broadcasted', msg.state

    children = AOMessage.all :conditions => ['parent_id = ?', msg.id]
    assert_equal 2, children.length

    2.times do |i|
      assert_equal chans[i], children[i].channel
      assert_equal msg.id, children[i].parent_id
      assert_not_nil children[i].guid
      assert_not_equal children[i].guid, msg.guid
    end
  end

  test "route ao broadcast override" do
    app = Application.make

    chans = [Channel.make(:account => app.account), Channel.make(:account => app.account)]

    msg = AOMessage.make_unsaved
    msg.strategy = 'broadcast'
    app.route_ao msg, 'test'

    assert_equal 'broadcasted', msg.state
  end

  test "application at rules" do
    app = Application.make
    app.at_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action('from','sms://2')
      ])
    ]
    chan = Channel.make :account_id => app.account_id

    msg = ATMessage.make_unsaved :from => 'sms://1', :account_id => app.account_id

    app.route_at msg, chan

    assert_equal 'sms://2', msg.from
  end

  test "route ao failover" do
    app = Application.make
    chans = 3.times.map {|i| Channel.make :account_id => app.account_id, :priority => i }
    ids = chans.map &:id
    msg = AOMessage.make_unsaved :account_id => app.account_id
    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
    assert_equal chans[0].id, msg.channel_id
    assert_equal ids.join(','), msg.candidate_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'queued', msg.state
    assert_equal chans[1].id, msg.channel_id
    assert_equal ids[1..-1].join(','), msg.candidate_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'queued', msg.state
    assert_equal chans[2].id, msg.channel_id
    assert_equal ids[2..-1].join(','), msg.candidate_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'failed', msg.state
    assert_equal chans[2].id, msg.channel_id
    assert_equal nil, msg.candidate_channels
  end

end
