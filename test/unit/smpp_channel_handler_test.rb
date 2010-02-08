require 'test_helper'

class SmppChannelHandlerTest < ActiveSupport::TestCase
  
  setup :initialize_objects

  def initialize_objects
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'smpp', :protocol => 'smpp')
  end
  
  test "should not save if host is blank" do
    @chan.configuration = {:port => 3200, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if port is blank" do
    @chan.configuration = {:host => 'host', :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if ton is blank" do
    @chan.configuration = {:host => 'host', :npi => 0, :port => 3200, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end  

  test "should not save if npi is blank" do
    @chan.configuration = {:host => 'host', :ton => 0, :port => 3200, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if user is blank" do
    @chan.configuration = {:host => 'host', :port => 3200, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if password is blank" do
    @chan.configuration = {:host => 'host', :port => 3200, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if encoding is blank" do
    @chan.configuration = {:host => 'host', :port => 3200, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password' }
    assert !@chan.save
  end
  
  test "should not save if port is not a number" do
    @chan.configuration = {:host => 'host', :port => 'foo', :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
  
  test "should not save if port is negative" do
    @chan.configuration = {:host => 'host', :port => -3200, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if ton is not a number" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => 'bar', :npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if npi is not a number" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => 0, :npi => 'bar', :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if ton is less than 0" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => -1, :npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if ton is greater than 7" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => 8, :npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if npi is less than 0" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => 0, :npi => -1, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end

  test "should not save if npi is greater than 7" do
    @chan.configuration = {:host => 'host', :port => 'foo', :ton => 0, :npi => 8, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert !@chan.save
  end
    
  test "should save" do
    @chan.configuration = {:host => 'host', :port => '3200', :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :encoding => 'utf16le', :system_type => 'smpp' }
    assert @chan.save
  end
end
