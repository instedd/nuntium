require 'test_helper'
require 'mocha'

class AccountTest < ActiveSupport::TestCase

  include Mocha::API
  include RulesEngine
  
  def setup
    @country = Country.create! :name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54'
    @carrier = Carrier.create! :country => @country, :name => 'Personal', :guid => "ABC123", :prefixes => '1, 2, 3'
  end

  test "should not save if name is blank" do
    account = Account.new :password => 'foo'
    assert !account.save
  end
  
  test "should not save if password is blank" do
    account = Account.new :name => 'account'
    assert !account.save
  end
  
  test "should not save if password confirmation fails" do
    account = Account.new :name => 'account', :password => 'foo', :password_confirmation => 'foo2'
    assert !account.save
  end
  
  test "should not save if name is taken" do
    Account.create! :name => 'account', :password => 'foo'
    account = Account.new :name => 'account', :password => 'foo2'
    assert !account.save
  end
  
  test "should save account" do
    account = Account.new :name => 'account', :password => 'foo', :password_confirmation => 'foo'
    assert account.save
  end
  
  test "should authenticate" do
    account1 = Account.create! :name => 'account', :password => 'foo'
    assert account1.authenticate('foo')
    assert !account1.authenticate('foo2')
  end
  
  test "should find by id if numerical" do
    account = Account.create! :name => 'account', :password => 'foo'
    found = Account.find_by_id_or_name(account.id.to_s)
    assert_equal account, found
  end
  
  test "should find by name if string" do
    account = Account.create! :name => 'account2', :password => 'foo'
    found = Account.find_by_id_or_name('account2')
    assert_equal account, found
  end
  
  test "route at saves mobile number" do
    account = Account.create! :name => 'account', :password => 'foo'
    
    msg = ATMessage.new :from => 'sms://+5678', :to => 'sms://1234', :subject => 'foo', :body => 'bar'
    msg.custom_attributes['country'] = 'ar'
    msg.custom_attributes['carrier'] = 'ABC123'
    
    account.route_at msg, nil
    
    nums = MobileNumber.all
    assert_equal 1, nums.length
    assert_equal '5678', nums[0].number
    assert_equal @country.id, nums[0].country_id
    assert_equal @carrier.id, nums[0].carrier_id
  end
  
  test "route at saves last channel" do
    account = Account.create! :name => 'account', :password => 'foo'
    app = create_app account
    app.use_address_source = true
    app.save!
    
    chan = new_channel account, 'chan'
    msg = ATMessage.new :from => 'sms://+5678', :to => 'sms://1234', :subject => 'foo', :body => 'bar'
    account.route_at msg, chan
    
    as = AddressSource.all
    assert_equal 1, as.length
    assert_equal '5678', as[0].address
    assert_equal account.id, as[0].account_id
    assert_equal app.id, as[0].application_id
    assert_equal chan.id, as[0].channel_id
  end
  
  test "route at does not save last channel if it's not bidirectional" do
    account = Account.create! :name => 'account', :password => 'foo'
    app = create_app account
    app.use_address_source = true
    app.save!
    
    chan = new_channel account, 'chan'
    chan.direction = Channel::Incoming
    chan.save!
    
    msg = ATMessage.new :from => 'sms://+5678', :to => 'sms://1234', :subject => 'foo', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal 0, AddressSource.count
  end
  
  test "apply at routing" do
    account = Account.create! :name => 'account', :password => 'foo'
    chan = new_channel account, 'chan'
    chan.at_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('subject', 'ONE')]) 
    ]
    chan.save!
    
    msg = ATMessage.new :subject => 'one', :from => 'sms://+5678', :to => 'sms://1234', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal 'ONE', msg.subject
    
    msg = ATMessage.new :subject => 'two', :from => 'sms://+5678', :to => 'sms://1234', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal 'two', msg.subject
  end
  
  test "apply app routing" do
    account = Account.create! :name => 'account', :password => 'foo'
    chan = new_channel account, 'chan'
    app1 = create_app account, 1
    app2 = create_app account, 2
    
    account.app_routing_rules = [
      rule([matching('subject', OP_EQUALS, 'one')], [action('application', 'application1')]),
      rule([matching('subject', OP_EQUALS, 'two')], [action('application', 'application2')])
    ]
    
    msg = ATMessage.new :subject => 'one', :from => 'sms://+5678', :to => 'sms://1234', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal app1.id, msg.application_id
    
    msg = ATMessage.new :subject => 'two', :from => 'sms://+5678', :to => 'sms://1234', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal app2.id, msg.application_id
  end
  
  test "skip app routing if messaga has an application property already" do
    account = Account.create! :name => 'account', :password => 'foo'
    chan = new_channel account, 'chan'
    app1 = create_app account, 1
    app2 = create_app account, 2
    
    account.app_routing_rules = [
      rule([], [action('application', 'application2')])
    ]
    
    msg = ATMessage.new :subject => 'one', :from => 'sms://1', :to => 'sms://2', :body => 'bar'
    msg.custom_attributes['application'] = 'application1'
    account.route_at msg, chan

    assert_equal app1.id, msg.application_id
  end
  
  test "at routing infer country" do
    account = Account.create! :name => 'account', :password => 'foo'
    chan = new_channel account, 'chan'
    app1 = create_app account, 1
    
    msg = ATMessage.new :subject => 'one', :from => 'sms://5467', :to => 'sms://2', :body => 'bar'
    account.route_at msg, chan
    
    assert_equal 'ar', msg.country
  end
end
