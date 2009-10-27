require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase
  test "should not save if name is blank" do
    app = Application.new(:password => 'foo')
    assert !app.save
  end
  
  test "should not save if password is blank" do
    app = Application.new(:name => 'app')
    assert !app.save
  end
  
  test "should not save if password confirmation fails" do
    app = Application.new(:name => 'app', :password => 'foo', :password_confirmation => 'foo2')
    assert !app.save
  end
  
  test "should not save if name is taken" do
    Application.create(:name => 'app', :password => 'foo')
    app = Application.new(:name => 'app', :password => 'foo2')
    assert !app.save
  end
  
  test "should save app" do
    app = Application.new(:name => 'app', :password => 'foo', :password_confirmation => 'foo')
    assert app.save
  end
  
  test "should find by name" do
    app1 = Application.create(:name => 'app', :password => 'foo')
    app2 = Application.find_by_name 'app'
    assert_equal app1.id, app2.id
  end
  
  test "should authenticate" do
    app1 = Application.create(:name => 'app', :password => 'foo')
    assert app1.authenticate('foo')
    assert !app1.authenticate('foo2')
  end
end
