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

class AccountTest < ActiveSupport::TestCase

  include RulesEngine

  def setup
    @account = Account.make :password => 'secret1'
    @app = @account.applications.make :password => 'secret2'
    @chan = QstServerChannel.make :account_id => @account.id
  end

  [:name, :password].each do |field|
    test "should not save if #{field} is blank" do
      @account.send("#{field}=", nil)
      assert !@account.save
    end
  end

  test "should not save if password confirmation fails" do
    account = Account.make_unsaved :password => 'foo', :password_confirmation => 'foo2'
    assert_false account.save
  end

  test "should not save if name is taken" do
    account = Account.make_unsaved :name => @account.name
    assert_false account.save
  end

  test "should authenticate" do
    account = Account.make :password => 'foo'
    assert account.authenticate('foo')
    assert !account.authenticate('foo2')
  end

  test "should find by id if numerical" do
    assert_equal @account, Account.find_by_id_or_name(@account.id.to_s)
  end

  test "should find by name if string" do
    assert_equal @account, Account.find_by_id_or_name(@account.name)
  end

  test "route at saves mobile number" do
    country = Country.make
    carrier = Carrier.make :country => country

    msg = AtMessage.make_unsaved
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid

    @account.route_at msg, @chan

    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.from.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end

  test "route at does not save mobile number if more than one country and/or carrier" do
    msg = AtMessage.make_unsaved
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']

    @account.route_at msg, @chan

    assert_equal 0, MobileNumber.count
  end

  test "route at saves last channel" do
    msg = AtMessage.make_unsaved
    @account.route_at msg, @chan

    as = AddressSource.all
    assert_equal 1, as.length
    assert_equal msg.from, as[0].address
    assert_equal @account.id, as[0].account_id
    assert_equal @app.id, as[0].application_id
    assert_equal @chan.id, as[0].channel_id
  end

  test "route at saves update updated_at for same channel" do
    previous_date = (Time.now - 10)
    msg = AtMessage.make_unsaved

    @account.address_sources.create! :address => msg.from, :application_id => @app.id, :channel_id => @chan.id, :updated_at => previous_date

    @account.route_at msg, @chan

    as = AddressSource.all
    assert_equal 1, as.length

    assert_equal msg.from, as[0].address
    assert_equal @account.id, as[0].account_id
    assert_equal @app.id, as[0].application_id
    assert_equal @chan.id, as[0].channel_id
    assert as[0].updated_at > previous_date
  end

  test "route at saves many last channels" do
    chan2 = QstServerChannel.make :account_id => @account.id

    msg1 = AtMessage.make_unsaved :from => 'sms://1234'
    @account.route_at msg1, @chan

    msg2 = AtMessage.make_unsaved :from => 'sms://1234'
    @account.route_at msg2, chan2

    as = AddressSource.all
    assert_equal 2, as.length

    assert_equal msg1.from, as[0].address
    assert_equal @account.id, as[0].account_id
    assert_equal @app.id, as[0].application_id
    assert_equal @chan.id, as[0].channel_id

    assert_equal msg2.from, as[1].address
    assert_equal @account.id, as[1].account_id
    assert_equal @app.id, as[1].application_id
    assert_equal chan2.id, as[1].channel_id
  end

  test "route at does not save last channel if it's not bidirectional" do
    @chan.direction = Channel::Incoming
    @chan.save!

    @account.route_at AtMessage.make_unsaved, @chan

    assert_equal 0, AddressSource.count
  end

  test "apply channel at routing" do
    @chan.at_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('subject', 'ONE')])
    ]
    @chan.save!

    msg = AtMessage.make_unsaved :subject => 'one'
    @account.route_at msg, @chan

    assert_equal 'ONE', msg.subject

    msg = AtMessage.make_unsaved :subject => 'two'
    @account.route_at msg, @chan

    assert_equal 'two', msg.subject
  end

  test "apply channel at routing cancels message" do
    @chan.at_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('cancel', 'true')])
    ]
    @chan.save!

    msg = AtMessage.make_unsaved :subject => 'one'
    @account.route_at msg, @chan

    assert_equal 'canceled', msg.state
    assert_not_nil msg.id
    assert_equal @chan.id, msg.channel_id
    assert_nil msg.application_id
  end

  test "apply app routing" do
    app2 = @account.applications.make

    @account.app_routing_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('application', @app.name)]),
      rule([matching('subject', OP_EQUALS, 'two')], [action('application', app2.name)])
    ]

    msg = AtMessage.make_unsaved :subject => 'one'
    @account.route_at msg, @chan

    assert_equal @app.id, msg.application_id

    msg = AtMessage.make_unsaved :subject => 'two'
    @account.route_at msg, @chan

    assert_equal app2.id, msg.application_id
  end

  test "skip app routing if message has an application property already" do
    app2 = @account.applications.make

    @account.app_routing_rules = [
      rule([], [action('application', app2.name)])
    ]

    msg = AtMessage.make_unsaved
    msg.custom_attributes['application'] = @app.name
    @account.route_at msg, @chan

    assert_equal @app.id, msg.application_id
  end

  test "at routing infer country" do
    country = Country.make
    carrier = Carrier.make :country => country

    msg = AtMessage.new :from => "sms://+#{country.phone_prefix}1234"
    @account.route_at msg, @chan

    assert_equal country.iso2, msg.country
  end

  test "at routing routes to channel's application" do
    app2 = @account.applications.make
    @chan.application_id = app2.id
    @chan.save!

    msg = AtMessage.make_unsaved
    @account.route_at msg, @chan

    assert_equal app2.id, msg.application_id
  end

  test "at routing routes to channel's application overriding custom attribute" do
    app2 = @account.applications.make
    @chan.application_id = app2.id
    @chan.save!

    msg = AtMessage.make_unsaved
    msg.custom_attributes['application'] = @app.name

    @account.route_at msg, @chan

    assert_equal app2.id, msg.application_id
  end

  test "at routing discards messages with same from and to addresses" do
    msg = AtMessage.make_unsaved :from => 'sms://123', :to => 'sms://123'

    @account.route_at msg, @chan

    assert_equal 'failed', msg.state
  end

  test "at routing assigns cost" do
    @chan.at_cost = 1.2
    @chan.save!

    msg = AtMessage.make_unsaved

    @account.route_at msg, @chan

    msg.reload

    assert_equal 1.2, msg.cost
  end

  test "authenticate with account and password" do
    account, app = Account.authenticate @account.name, 'secret1'
    assert_equal account, @account
    assert_nil app
  end

  test "authenticate with account and password fails" do
    account, app = Account.authenticate @account.name, 'secret2'
    assert_nil account
    assert_nil app
  end

  test "authenticate with account and password fails if only application is true" do
    account, app = Account.authenticate @account.name, 'secret1', :only_application => true
    assert_nil account
    assert_nil app
  end

  test "authenticate with account/application and password" do
    account, app = Account.authenticate "#{@account.name}/#{@app.name}", 'secret2'
    assert_equal account, @account
    assert_equal app, @app
  end

  test "authenticate with account/application and password fails" do
    account, app = Account.authenticate "#{@account.name}/#{@app.name}", 'secret3'
    assert_nil account
    assert_nil app
  end

  test "authenticate with application@account and password" do
    account, app = Account.authenticate "#{@app.name}@#{@account.name}", 'secret2'
    assert_equal account, @account
    assert_equal app, @app
  end

  test "authenticate with application@account and password fails" do
    account, app = Account.authenticate "#{@app.name}@#{@account.name}", 'secret3'
    assert_nil account
    assert_nil app
  end

  test "should update account lifespan when created" do
    account = Account.make_unsaved

    Telemetry::Lifespan.expects(:touch_account).with(account)

    account.save
  end

  test "should update account lifespan when updated" do
    account = Account.make

    Telemetry::Lifespan.expects(:touch_account).with(account)

    account.touch
    account.save
  end

  test "should update account lifespan when destroyed" do
    account = Account.make

    Telemetry::Lifespan.expects(:touch_account).with(account)

    account.destroy
  end
end
