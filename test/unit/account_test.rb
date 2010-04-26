require 'test_helper'
require 'mocha'

class AccountTest < ActiveSupport::TestCase

  include Mocha::API

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
  
  test "should find by name" do
    account1 = Account.create!(:name => 'account', :password => 'foo')
    account2 = Account.find_by_name 'account'
    assert_equal account1.id, account2.id
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
  
end
