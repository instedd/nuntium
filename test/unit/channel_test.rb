require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make
  end

  def assert_eq_rules_xml(expected, actual)
    expected = expected.ensure_array
    actual = actual.ensure_array

    expected = { :v => expected }.with_indifferent_access[:v]
    actual = { :v => actual }.with_indifferent_access[:v]

    assert_equal expected.length, actual.length
    expected.zip(actual).each do |e_rule,a_rule|
      assert_equal e_rule[:stop].to_s, a_rule[:stop].to_s
      assert_equal e_rule[:actions], a_rule[:actions][:action].ensure_array
      assert_equal e_rule[:matchings], a_rule[:matchings][:matching].ensure_array
    end
  end

  [:name, :kind, :protocol, :account_id].each do |field|
    test "should validate presence of #{field}" do
      @chan.send("#{field}=", nil)
      assert_false @chan.save
    end
  end

  [' ', '$', '.', '!', '~', ')', '(', '%', '^', '/', '\\'].each do |sym|
    test "should not save if name has symbol #{sym}" do
      @chan.name = "foo#{sym}bar"
      assert_false @chan.save
    end
  end

  test "should not save if direction is wrong" do
    @chan.direction = 100
    assert_false @chan.save
  end

  test "should not save if name is taken" do
    chan2 = QstServerChannel.make_unsaved :name => @chan.name, :account => @chan.account
    assert_false chan2.save
  end

  test "should save if name is taken in another account" do
    account2 = Account.make
    chan2 = QstServerChannel.make_unsaved :name => @chan.name, :account => account2
    assert chan2.save
  end

  test "should be enabled by default" do
    assert @chan.enabled
  end

  test "should serialize/deserialize ao_rules" do
    @chan.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching(:from, RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action(:ca1,'whitness')
      ])
    ]

    @chan.save!

    chan_stored = Channel.find_by_id(@chan.id)

    res = RulesEngine.apply({:from => 'sms://1'}, chan_stored.ao_rules)
    assert_equal 'whitness', res[:ca1]
  end

  test "should serialize/deserialize at_rules" do
    @chan.at_rules = [
      RulesEngine.rule([
        RulesEngine.matching(:from, RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action(:ca1,'whitness')
      ])
    ]

    @chan.save!

    chan_stored = Channel.find_by_id(@chan.id)

    res = RulesEngine.apply({:from => 'sms://1'}, chan_stored.at_rules)
    assert_equal 'whitness', res[:ca1]
  end

  test "route ao applies ao rules" do
    @chan.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action('from','sms://2')
      ])
    ]

    msg = AoMessage.make_unsaved :from => 'sms://1', :account => @chan.account, :application => @chan.application
    @chan.route_ao msg, 'test'

    assert_equal 'sms://2', msg.from
  end

  test "route ao applies ao rules and cancels message" do
    @chan.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action('cancel','true')
      ])
    ]

    msg = AoMessage.make_unsaved :from => 'sms://1', :account => @chan.account, :application => @chan.application
    @chan.route_ao msg, 'test'

    assert_equal 'canceled', msg.state
    assert_equal @chan.id, msg.channel_id
    assert_not_nil msg.id
  end

  test "route ao discards message with same from and to" do
    msg = AoMessage.make_unsaved :from => 'sms://123', :to => 'sms://123', :account => @chan.account, :application => @chan.application
    @chan.expects(:handle).never
    @chan.route_ao msg, 'test'

    assert_equal 'failed', msg.state
  end

  test "route ao discards message with invalid to address" do
    msg = AoMessage.make_unsaved :to => 'sms://hello', :account => @chan.account, :application => @chan.application
    @chan.route_ao msg, 'test'

    msg.reload
    assert_equal 'failed', msg.state
  end

  test "to xml" do
    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    chan = xml[:channel]
    assert_equal @chan.name, chan[:name]
    assert_equal @chan.kind, chan[:kind]
    assert_equal @chan.protocol, chan[:protocol]
    assert_equal 'bidirectional', chan[:direction]
    assert_equal 'true', chan[:enabled]
    assert_equal @chan.priority.to_s, chan[:priority]
    assert_nil chan[:application]
  end

  test "to xml with application" do
    @chan.application = Application.make(:account => @chan.account)

    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    chan = xml[:channel]
    assert_equal @chan.application.name, chan[:application]
  end

  test "to xml configuration" do
    @chan.kind = 'clickatell'
    @chan.direction = 'incoming'
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }

    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    config = xml[:channel][:configuration]
    properties = config[:property]

    assert_equal 3, properties.length
    @chan.configuration.each do |name, value|
      found = false
      properties.each do |prop|
        if prop[:name] == name.to_s
          assert_equal value, prop[:value], "Property #{name} expected to be #{value} but was #{prop[:value]}"
          found = true
        end
      end
      if name.to_s.include? 'password'
        assert_false found, "Property #{name} should not be exposed"
      else
        assert_true found, "Property #{name} not found"
      end
    end
  end

  test "to xml restrictions" do
    @chan.restrictions['single'] = 'one'
    @chan.restrictions['multi'] = ['a', 'b']

    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    properties = xml[:channel][:restrictions][:property]

    assert_equal 3, properties.length
    @chan.restrictions.each_multivalue do |name, values|
      values.each do |value|
        found = false
        properties.each do |prop|
          found = true if prop[:name] == name.to_s and value == prop[:value]
        end
        assert_true found, "Property #{name} not found"
      end
    end
  end

  test "to xml ao_rules and at_rules" do
    @chan.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action('from','sms://2')
      ], true),
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://3')
      ],[
        RulesEngine.action('from','sms://4'),
        RulesEngine.action('body','lorem')
      ])
    ]

    @chan.at_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1'),
        RulesEngine.matching('body', RulesEngine::OP_EQUALS, 'ipsum')
      ],[
        RulesEngine.action('ca1','whitness')
      ])
    ]

    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    ao_rules = xml[:channel][:ao_rules][:rule].ensure_array
    at_rules = xml[:channel][:at_rules][:rule].ensure_array

    assert_eq_rules_xml @chan.ao_rules, ao_rules
    assert_eq_rules_xml @chan.at_rules, at_rules
  end

  test "to xml with last activity at" do
    now = Time.parse "2011-06-12 15:15:11 UTC"
    @chan.last_activity_at = now

    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    chan = xml[:channel]
    assert_equal "2011-06-12 15:15:11 UTC", chan[:last_activity_at]
  end

  test "from xml with empty restrictions creates the empty hash" do
    c = Channel.from_xml('<channel><restrictions/></channel>')

    assert_not_nil c.read_attribute(:restrictions)
  end

  test "to json" do
    chan = JSON.parse(@chan.to_json).with_indifferent_access

    assert_equal @chan.name, chan[:name]
    assert_equal @chan.kind, chan[:kind]
    assert_equal @chan.protocol, chan[:protocol]
    assert_equal 'bidirectional', chan[:direction]
    assert_true chan[:enabled]
    assert_equal @chan.priority, chan[:priority]
    assert_nil chan[:application]
    assert_equal 0, chan[:queued_ao_messages_count]
    assert !chan[:connected]
  end

  test "to json with application" do
    @chan.application = Application.make(:account => @chan.account)

    chan = JSON.parse(@chan.to_json).with_indifferent_access
    assert_equal @chan.application.name, chan[:application]
  end

  test "to json configuration" do
    @chan.kind = 'clickatell'
    @chan.direction = 'incoming'
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }

    chan = JSON.parse(@chan.to_json).with_indifferent_access
    properties = chan[:configuration]

    assert_equal 3, properties.length
    @chan.configuration.each do |name, value|
      found = false
      properties.each do |prop|
        if prop[:name] == name.to_s
          assert_equal value, prop[:value], "Property #{name} expected to be #{value} but was #{prop[:value]}"
          found = true
        end
      end
      if name.to_s.include? 'password'
        assert_false found, "Property #{name} should not be exposed"
      else
        assert_true found, "Property #{name} not found"
      end
    end
  end

  test "to json with passwords" do
    @chan.kind = 'clickatell'
    @chan.direction = 'incoming'
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }

    chan = JSON.parse(@chan.to_json(:include_passwords =>  true)).with_indifferent_access
    properties = chan[:configuration]

    assert_equal 5, properties.length
  end

  test "to json restrictions" do
    @chan.restrictions['single'] = 'one'
    @chan.restrictions['multi'] = ['a', 'b']

    chan = JSON.parse(@chan.to_json).with_indifferent_access
    properties = chan[:restrictions]

    assert_equal 2, properties.length
    @chan.restrictions.each do |name, value|
      found = false
      properties.each do |prop|
        found = true if prop[:name] == name.to_s and value == prop[:value]
      end
      assert_true found, "Property #{name} not found"
    end
  end

  test "to json ao_rules and at_rules" do
    @chan.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1')
      ],[
        RulesEngine.action('from','sms://2')
      ], true),
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://3')
      ],[
        RulesEngine.action('from','sms://4'),
        RulesEngine.action('body','lorem')
      ])
    ]

    @chan.at_rules = [
      RulesEngine.rule([
        RulesEngine.matching('from', RulesEngine::OP_EQUALS, 'sms://1'),
        RulesEngine.matching('body', RulesEngine::OP_EQUALS, 'ipsum')
      ],[
        RulesEngine.action('ca1','whitness')
      ])
    ]

    chan = JSON.parse(@chan.to_json).with_indifferent_access

    assert_equal @chan.ao_rules, chan[:ao_rules]
    assert_equal @chan.at_rules, chan[:at_rules]
  end

  test "to json last activity at" do
    now = Time.now.utc
    @chan.last_activity_at = now

    chan = JSON.parse(@chan.to_json).with_indifferent_access

    assert_equal now.to_json, %Q("#{chan[:last_activity_at]}")
  end

  test "to json queued ao messages count" do
    AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    chan = JSON.parse(@chan.to_json).with_indifferent_access
    assert_equal 1, chan[:queued_ao_messages_count]
  end

  test "to json connected" do
    @chan.connected = true
    chan = JSON.parse(@chan.to_json).with_indifferent_access
    assert_equal true, chan[:connected]
  end

  test "sort candidate channels first by priority, then by paused" do
    zero_was_first = false
    zero_was_second = false
    three_was_fourth = false
    three_was_fifth = false
    10.times do
      chans = []
      chans << QstServerChannel.make_unsaved(:name => '0', :priority => 1)
      chans << QstServerChannel.make_unsaved(:name => '1', :priority => 1)
      chans << QstServerChannel.make_unsaved(:name => '2', :priority => 1, :paused => true)
      chans << QstServerChannel.make_unsaved(:name => '3', :priority => 2)
      chans << QstServerChannel.make_unsaved(:name => '4', :priority => 2)
      chans << QstServerChannel.make_unsaved(:name => '5', :priority => 2, :paused => true)

      names = chans.map &:name

      chans.shuffle!

      Channel.sort_candidate! chans

      [0, 1, 2].each do |i|
        assert_equal 1, chans.select{|x| x.name == i.to_s}.first.priority
      end
      [3, 4, 5].each do |i|
        assert_equal 2, chans.select{|x| x.name == i.to_s}.first.priority
      end

      chans.map! &:name

      [0, 1].each do |less|
        [2, 3, 4, 5].each do |great|
          assert_true chans.index(names[less]) < chans.index(names[great])
        end
      end
      [2].each do |less|
        [3, 4, 5].each do |great|
          assert_true chans.index(names[less]) < chans.index(names[great])
        end
      end
      [3, 4].each do |less|
        [5].each do |great|
          assert_true chans.index(names[less]) < chans.index(names[great])
        end
      end
      zero_was_first ||= chans.index('0') == 0
      zero_was_second ||= chans.index('0') == 1
      three_was_fourth ||= chans.index('3') == 3
      three_was_fifth ||= chans.index('3') == 4
    end
    assert_true zero_was_first
    assert_true zero_was_second
    assert_true three_was_fourth
    assert_true three_was_fifth
  end

  test "disable channel re-routes" do
    chan2 = QstServerChannel.make :account => @chan.account

    app = Application.make :account => @chan.account
    msg = AoMessage.make :account => @chan.account, :application => @chan.account.applications.make, :channel => @chan, :state => 'queued'

    @chan.enabled = false
    @chan.save!

    @chan.reload
    chan2.reload
    msg.reload

    assert_false @chan.enabled
    assert_true chan2.enabled
    assert_equal chan2.id, msg.channel_id
    assert_equal 1, @chan.requeued_messages_count
  end
end
