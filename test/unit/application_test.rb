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

class ApplicationTest < ActiveSupport::TestCase

  include RulesEngine

  test "check modified" do
    app = Application.make!
    chan1 = QstServerChannel.make! :account_id => app.account_id
    chan2 = QstServerChannel.make! :account_id => app.account_id, :priority => chan1.priority - 10

    msg = AoMessage.make
    app.route_ao msg, 'test'
    assert_equal chan2.id, msg.channel_id

    chan2.priority = chan1.priority + 10
    chan2.save!

    msg = AoMessage.make
    app.route_ao msg, 'test'
    assert_equal chan1.id, msg.channel_id
  end

  test "should create worker queue on create" do
    app = Application.make!
    wqs = WorkerQueue.all
    assert_equal 1, wqs.length
    assert_equal "application_queue.#{app.id}", wqs[0].queue_name
    assert_equal "fast", wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end

  test "should destroy worker queue on destroy" do
    app = Application.make!
    app.destroy

    assert_equal 0, WorkerQueue.count
  end

  test "should bind queue on create" do
    binded = nil

    Queues.expects(:bind_application).with do |a|
      binded = a
      true
    end

    app = Application.make!
    assert_same app, binded
  end

  ['get', 'post'].each do |method|
    test "should enqueue http #{method} callback" do
      app = Application.make! :"http_#{method}_callback"

      msg = AtMessage.create!(:account => app.account, :subject => 'foo')

      Queues.expects(:publish_application).with do |a, j|
        a.id == app.id and
          j.kind_of?(SendInterfaceCallbackJob) and
          j.account_id == app.account.id and
          j.application_id == app.id and
          j.message_id == msg.id
      end

      app.route_at msg, QstServerChannel.make!(:account_id => app.account_id)
    end
  end

  test "route ao protocol not found in message" do
    app = Application.make!

    msg = AoMessage.make :to => '+5678'
    app.route_ao msg, 'test'

    messages = AoMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  end

  test "route ao channel not found for protocol" do
    app = Application.make!

    msg = AoMessage.make :to => 'unknown://+5678'
    app.route_ao msg, 'test'

    messages = AoMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
  end

  test "route select channel based on protocol" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol'
    chan2 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol2'

    msg = AoMessage.make :to => 'protocol2://Someone else'
    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "candidate channels" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol'
    chan2 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol2'

    msg = AoMessage.make :to => 'protocol2://Someone else'
    channels = app.candidate_channels_for_ao msg

    assert_equal [chan2], channels
  end

  test "candidate channels ordered by priority" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol', :priority => 2
    chan2 = QstServerChannel.make! :account_id => app.account_id, :protocol => 'protocol', :priority => 1

    msg = AoMessage.make :to => 'protocol://Someone else'
    channels = app.candidate_channels_for_ao msg

    assert_equal [chan2.id, chan1.id], channels.map(&:id)
  end

  test "route ao saves mobile numbers" do
    app = Application.make!
    country = Country.make!
    carrier = Carrier.make! country: country

    msg = AoMessage.make
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
    app = Application.make!

    msg = AoMessage.make
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']

    app.route_ao msg, 'test'

    assert_equal 0, MobileNumber.count
  end

  test "route ao updates mobile numbers" do
    app = Application.make!
    country = Country.make!
    carrier = Carrier.make! country: country

    MobileNumber.create! :number => '5678', :country_id => country.id + 1

    msg = AoMessage.make :to => 'sms://+5678'
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
    app = Application.make!
    country = Country.make!
    carrier = Carrier.make! country: country
    MobileNumber.create! :number => '5678', :country_id => country.id, :carrier_id => carrier.id

    msg = AoMessage.make :to => 'sms://+5678'

    app.route_ao msg, 'test'

    assert_equal country.iso2, msg.country
    assert_equal carrier.guid, msg.carrier
  end

  test "route ao doesnt complete country or carrier if present" do
    app = Application.make!
    country = Country.make!
    carrier = Carrier.make! country: country
    MobileNumber.create! :number => '5678', :country_id => country.id, :carrier_id => carrier.id

    msg = AoMessage.make :to => 'sms://+5678', :country => 'foo_country', :carrier => 'foo_carrier'

    app.route_ao msg, 'test'

    assert_equal 'foo_country', msg.country
    assert_equal 'foo_carrier', msg.carrier
  end

  test "route ao doesnt complete country or carrier if mobile number is missing" do
    app = Application.make!

    msg = AoMessage.make :to => 'sms://+5678'

    app.route_ao msg, 'test'

    assert_equal nil, msg.country
    assert_equal nil, msg.carrier
  end

  test "route ao filter channel because of country" do
    app = Application.make!

    msg = AoMessage.make
    msg.custom_attributes['country'] = 'br'

    chan1 = QstServerChannel.make :account_id => app.account_id
    chan1.restrictions['country'] = 'ar'
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'failed', msg.state
  end

  test "route ao filter channel because of country 2" do
    app = Application.make!

    msg = AoMessage.make
    msg.custom_attributes['country'] = ['br', 'bz']

    chan1 = QstServerChannel.make :account_id => app.account_id
    chan1.restrictions['country'] = ['ar', 'br']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
  end

  test "route ao filter channel because belongs to application" do
    account = Account.make!
    app1 = account.applications.make!
    app2 = account.applications.make!

    msg = AoMessage.make

    chan1 = QstServerChannel.make! :account_id => account.id, :application => app2
    chan2 = QstServerChannel.make! :account_id => account.id

    app1.route_ao msg, 'test'

    assert_nil msg.failover_channels
    assert_equal chan2.id, msg.channel_id
  end

  test "route ao test filter when empty value passes" do
    app = Application.make!

    msg = AoMessage.make

    chan1 = QstServerChannel.make :account_id => app.account_id
    chan1.restrictions['country'] = ['ar', '']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
  end

  test "route ao test filter when empty value does not pass" do
    app = Application.make!

    msg = AoMessage.make

    chan1 = QstServerChannel.make :account_id => app.account_id
    chan1.restrictions['country'] = ['ar']
    chan1.save!

    app.route_ao msg, 'test'

    assert_equal 'failed', msg.state
  end

  test "route ao use last channel" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id
    chan2 = QstServerChannel.make! :account_id => app.account_id, :priority => chan1.priority + 10

    msg = AoMessage.make :to => 'sms://+5678'

    AddressSource.create! :account_id => app.account.id, :application_id => app.id, :channel_id => chan2.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "route ao use last recent channel" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id
    chan2 = QstServerChannel.make! :account_id => app.account_id,  :priority => chan1.priority + 10
    chan3 = QstServerChannel.make! :account_id => app.account_id,  :priority => chan1.priority + 20

    msg = AoMessage.make :to => 'sms://+5678'

    app.account.address_sources.create! :application_id => app.id, :channel_id => chan1.id, :address => msg.to, :updated_at => (Time.now - 10)
    app.account.address_sources.create! :application_id => app.id, :channel_id => chan3.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan3.id, msg.channel_id
  end

  test "route ao use last recent channel that is a candidate" do
    app = Application.make!

    chan1 = QstServerChannel.make! :account_id => app.account_id
    chan2 = QstServerChannel.make! :account_id => app.account_id,  :priority => chan1.priority + 10
    chan3 = QstServerChannel.make! :account_id => app.account_id,  :priority => chan1.priority + 20, :enabled => false

    msg = AoMessage.make :to => 'sms://+5678'

    app.account.address_sources.create! :application_id => app.id, :channel_id => chan1.id, :address => msg.to, :updated_at => (Time.now - 10)
    app.account.address_sources.create! :application_id => app.id, :channel_id => chan3.id, :address => msg.to

    app.route_ao msg, 'test'

    assert_equal chan1.id, msg.channel_id
  end

  test "route ao use suggested channel" do
    app = Application.make!
    chan1 = QstServerChannel.make! :account_id => app.account_id
    chan2 = QstServerChannel.make! :account_id => app.account_id,  :priority => chan1.priority + 10

    msg = AoMessage.make
    msg.suggested_channel = chan2.name
    app.route_ao msg, 'test'

    assert_equal chan2.id, msg.channel_id
  end

  test "route ao infer country" do
    app = Application.make!
    chan = QstServerChannel.make! :account_id => app.account_id
    country = Country.make!

    msg = AoMessage.make :to => "sms://+#{country.phone_prefix}1234"
    app.route_ao msg, 'test'

    assert_equal country.iso2, msg.country
  end

  test "route ao broadcast" do
    app = Application.make! :broadcast

    2.times { QstServerChannel.make!(:account_id => app.account_id) }
    chans = app.account.channels

    msg = AoMessage.make
    app.route_ao msg, 'test'

    assert_nil msg.channel
    assert_equal 'broadcasted', msg.state

    children = msg.children
    assert_equal 2, children.length

    2.times do |i|
      assert_equal chans[i], children[i].channel
      assert_equal msg.id, children[i].parent_id
      assert_not_nil children[i].guid
      assert_not_equal children[i].guid, msg.guid
    end
  end

  test "route ao broadcast override" do
    app = Application.make!

    chans = [QstServerChannel.make!(:account_id => app.account_id), QstServerChannel.make!(:account_id => app.account_id)]

    msg = AoMessage.make
    msg.strategy = 'broadcast'
    app.route_ao msg, 'test'

    assert_equal 'broadcasted', msg.state
  end

  test "application at rules" do
    app = Application.make!
    app.at_rules = [
      rule([
        matching('from', OP_EQUALS, 'sms://1')
      ],[
        action('from','sms://2')
      ])
    ]
    chan = QstServerChannel.make! :account_id => app.account_id

    msg = app.account.at_messages.make :from => 'sms://1'

    app.route_at msg, chan

    assert_equal 'sms://2', msg.from
  end

  test "application at rules cancels message" do
    app = Application.make!
    app.interface = 'http_get_callback'
    app.at_rules = [
      rule([
        matching('from', OP_EQUALS, 'sms://1')
      ],[
        action('cancel','true')
      ])
    ]
    chan = QstServerChannel.make! :account_id => app.account_id

    msg = app.account.at_messages.make :from => 'sms://1'

    Queues.expects(:publish_application).never

    app.route_at msg, chan

    assert_equal 'canceled', msg.state
    assert_not_nil msg.id
    assert_equal app.id, msg.application_id
  end

  test "route ao failover" do
    app = Application.make!
    chans = 3.times.map {|i| QstServerChannel.make! :account_id => app.account_id,  :priority => i }
    ids = chans.map &:id
    msg = app.account.ao_messages.make
    app.route_ao msg, 'test'

    assert_equal 'queued', msg.state
    assert_equal chans[0].id, msg.channel_id
    assert_equal ids[1 .. -1].join(','), msg.failover_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'queued', msg.state
    assert_equal chans[1].id, msg.channel_id
    assert_equal ids[2..-1].join(','), msg.failover_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'queued', msg.state
    assert_equal chans[2].id, msg.channel_id
    assert_nil msg.failover_channels

    msg.reload

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal 'failed', msg.state
    assert_equal chans[2].id, msg.channel_id
    assert_nil msg.failover_channels
  end

  test "route ao rules cancels message" do
    app = Application.make!
    app.ao_rules = [
        rule([
          matching('from', OP_EQUALS, 'sms://1')
        ],[
          action('cancel', "true")
        ])
    ]
    msg = app.account.ao_messages.make :from => 'sms://1'
    app.route_ao msg, 'test'

    assert_equal 'canceled', msg.state
    assert_not_nil msg.id
    assert_nil msg.channel_id
  end

  test "route ao failover resets to original before rerouting" do
    app = Application.make!
    chans = 2.times.map {|i| QstServerChannel.make :account_id => app.account_id, :priority => i }
    chans.each_with_index do |chan, i|
      chan.ao_rules = [
        rule([
          matching('from', OP_EQUALS, 'sms://1')
        ],[
          action('from',"sms://#{i + 2}")
        ])
      ]
    end
    chans.each &:'save!'

    msg = app.account.ao_messages.make :from => 'sms://1'
    app.route_ao msg, 'test'

    msg.reload

    assert_equal chans[0].id, msg.channel_id
    assert_equal 'sms://2', msg.from

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal chans[1].id, msg.channel_id
    assert_equal 'sms://3', msg.from
  end

  test "route ao failover resets to original before rerouting using custom attributes" do
    app = Application.make!
    chans = 2.times.map {|i| QstServerChannel.make :account_id => app.account_id, :priority => i }
    chans[0].ao_rules = [
      rule([
        matching('cust', OP_EQUALS, 'foo')
      ],[
        action('cust',"bar")
      ])
    ]
    chans[1].ao_rules = [
      rule([
        matching('cust', OP_EQUALS, 'foo')
      ],[
        action('cust',"baz")
      ])
    ]
    chans.each &:'save!'

    msg = app.account.ao_messages.make :from => 'sms://1'
    msg.custom_attributes['cust'] = 'foo'
    app.route_ao msg, 'test'

    msg.reload

    assert_equal chans[0].id, msg.channel_id
    assert_equal 'bar', msg.custom_attributes['cust']

    msg.state = 'failed'
    msg.save!

    msg.reload

    assert_equal chans[1].id, msg.channel_id
    assert_equal 'baz', msg.custom_attributes['cust']
  end

  test "route ao assigns cost" do
    app = Application.make!
    chan = QstServerChannel.make! :account_id => app.account_id, :ao_cost => 1.2

    msg = app.account.ao_messages.make
    app.route_ao msg, 'test'

    msg.reload

    assert_equal 1.2, msg.cost
  end

  test "should not create if password is blank" do
    app = Application.make
    app.password = app.password_confirmation = ''
    assert_false app.save
  end

  test "should not save if password confirmation is wrong" do
    app = Application.make! password: 'foo'
    app.password_confirmation = 'foo2'
    assert_false app.save
  end

  test "should authenticate" do
    app = Application.make! password: 'foo', password_confirmation: 'foo'
    assert app.authenticate('foo')
  end

  test "should keep old password if save with blank password" do
    app = Application.make! password: 'foo', password_confirmation: 'foo'
    app.password = app.password_confirmation = ''
    app.save!

    app.reload

    assert app.authenticate('foo')
  end

  test "should rehash password after password changed" do
    app = Application.make! password: 'foo', password_confirmation: 'foo'
    app.password = app.password_confirmation = 'foo2'
    app.save!

    app.reload

    assert app.authenticate('foo2')
  end

  test "should update application lifespan when created" do
    account = Account.make!
    application = Application.make account: account

    Telemetry::Lifespan.expects(:touch_application).with(application)

    application.save
  end

  test "should update application lifespan when updated" do
    application = Application.make!

    Telemetry::Lifespan.expects(:touch_application).with(application)

    application.touch
    application.save
  end

  test "should update application lifespan when destroyed" do
    application = Application.make!

    Telemetry::Lifespan.expects(:touch_application).with(application)

    application.destroy
  end

  test "should update account lifespan when created" do
    account = Account.make!
    application = Application.make account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    application.save
  end

  test "should update account lifespan when updated" do
    account = Account.make!
    application = Application.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    application.touch
    application.save
  end

  test "should update account lifespan when destroyed" do
    account = Account.make!
    application = Application.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    application.destroy
  end
end
