require 'test_helper'
require 'mocha'

class AccountTest < ActiveSupport::TestCase

  include Mocha::API
  include RulesEngine
  
  def setup
    @account = Account.make
    @app = Application.make :account => @account
    @chan = new_channel @account, 'chan'
  end

  [:name, :password].each do |field|
    test "should not save if #{field} is blank" do
      @account.send("#{field}=", nil)
      assert !@account.save
    end
  end
  
  test "should not save if password confirmation fails" do
    account = Account.make_unsaved :password => 'foo', :password_confirmation => 'foo2'
    assert !@account.save
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
  
    msg = ATMessage.make_unsaved
    msg.custom_attributes['country'] = country.iso2
    msg.custom_attributes['carrier'] = carrier.guid
    
    @account.route_at msg, nil
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal msg.from.mobile_number, nums[0].number
    assert_equal country.id, nums[0].country_id
    assert_equal carrier.id, nums[0].carrier_id
  end
  
  test "route at does not save mobile number if more than one country and/or carrier" do
    msg = ATMessage.make_unsaved
    msg.custom_attributes['country'] = ['ar', 'br']
    msg.custom_attributes['carrier'] = ['ABC123', 'XYZ']
    
    @account.route_at msg, nil
    
    assert_equal 0, MobileNumber.count
  end
  
  test "route at saves last channel" do
    msg = ATMessage.make_unsaved
    @account.route_at msg, @chan
    
    as = AddressSource.all
    assert_equal 1, as.length
    assert_equal msg.from.mobile_number, as[0].address
    assert_equal @account.id, as[0].account_id
    assert_equal @app.id, as[0].application_id
    assert_equal @chan.id, as[0].channel_id
  end
  
  test "route at does not save last channel if it's not bidirectional" do
    @chan.direction = Channel::Incoming
    @chan.save!
    
    @account.route_at ATMessage.make_unsaved, @chan
    
    assert_equal 0, AddressSource.count
  end
  
  test "apply at routing" do
    @chan.at_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('subject', 'ONE')]) 
    ]
    @chan.save!
    
    msg = ATMessage.make_unsaved :subject => 'one'
    @account.route_at msg, @chan
    
    assert_equal 'ONE', msg.subject
    
    msg = ATMessage.make_unsaved :subject => 'two'
    @account.route_at msg, @chan
    
    assert_equal 'two', msg.subject
  end
  
  test "apply app routing" do
    app2 = create_app @account, 2
    
    @account.app_routing_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('application', @app.name)]),
      rule([matching('subject', OP_EQUALS, 'two')], [action('application', app2.name)])
    ]
    
    msg = ATMessage.make_unsaved :subject => 'one'
    @account.route_at msg, @chan
    
    assert_equal @app.id, msg.application_id
    
    msg = ATMessage.make_unsaved :subject => 'two'
    @account.route_at msg, @chan
    
    assert_equal app2.id, msg.application_id
  end
  
  test "skip app routing if message has an application property already" do
    app2 = create_app @account, 2
    
    @account.app_routing_rules = [
      rule([], [action('application', app2.name)])
    ]
    
    msg = ATMessage.make_unsaved
    msg.custom_attributes['application'] = @app.name
    @account.route_at msg, @chan

    assert_equal @app.id, msg.application_id
  end
  
  test "at routing infer country" do
    country = Country.make
    carrier = Carrier.make :country => country
    
    msg = ATMessage.new :from => "sms://+#{country.phone_prefix}1234"
    @account.route_at msg, @chan
    
    assert_equal country.iso2, msg.country
  end
  
  test "at routing routes to channel's application" do
    app2 = create_app @account, 2
    @chan.application_id = app2.id
    @chan.save!
    
    msg = ATMessage.make_unsaved
    @account.route_at msg, @chan
    
    assert_equal app2.id, msg.application_id
  end
  
  test "at routing routes to channel's application overriding custom attribute" do
    app2 = create_app @account, 2
    @chan.application_id = app2.id
    @chan.save!
    
    msg = ATMessage.make_unsaved
    msg.custom_attributes['application'] = @app.name
    
    @account.route_at msg, @chan
    
    assert_equal app2.id, msg.application_id
  end
end
