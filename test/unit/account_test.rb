require 'test_helper'
require 'mocha'

class AccountTest < ActiveSupport::TestCase

  include Mocha::API
  
  def setup
    Rails.cache.clear
  
    @country = Country.create!(:name => 'Argentina', :iso2 => 'ar', :iso3 =>'arg', :phone_prefix => '54')
    @carrier = Carrier.create!(:country => @country, :name => 'Personal', :guid => "ABC123", :prefixes => '1, 2, 3')
  end

  test "should not save if name is blank" do
    account = Account.new(:password => 'foo')
    assert !account.save
  end
  
  test "should not save if password is blank" do
    account = Account.new(:name => 'account')
    assert !account.save
  end
  
  test "should not save if password confirmation fails" do
    account = Account.new(:name => 'account', :password => 'foo', :password_confirmation => 'foo2')
    assert !account.save
  end
  
  test "should not save if name is taken" do
    Account.create!(:name => 'account', :password => 'foo')
    account = Account.new(:name => 'account', :password => 'foo2')
    assert !account.save
  end
  
  test "should save account" do
    account = Account.new(:name => 'account', :password => 'foo', :password_confirmation => 'foo')
    assert account.save
  end
  
  test "should authenticate" do
    account1 = Account.create!(:name => 'account', :password => 'foo')
    assert account1.authenticate('foo')
    assert !account1.authenticate('foo2')
  end
  
  test "should find by id if numerical" do
    account = Account.create!(:name => 'account', :password => 'foo')
    found = Account.find_by_id_or_name(account.id.to_s)
    assert_equal account, found
  end
  
  test "should find by name if string" do
    account = Account.create!(:name => 'account2', :password => 'foo')
    found = Account.find_by_id_or_name('account2')
    assert_equal account, found
  end
  
  test "at routing saves mobile number" do
    account = Account.create!(:name => 'account', :password => 'foo')
    
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
  
end
