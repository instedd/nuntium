require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  def setup
    @account = Account.create(:name => 'account', :password => 'foo')
    @chan = Channel.new :name =>'channel', :account_id => @account.id, :kind => 'qst_server', :protocol => 'sms', :direction => Channel::Bidirectional
    @chan.configuration = {:password => 'foo', :password_confirmation => 'foo'}
  end
  
  [:name, :kind, :protocol, :account_id].each do |field|
    test "should validate presence of #{field}" do
      @chan.send("#{field}=", nil)
      assert !@chan.save
    end
  end
  
  [' ', '$', '.', '!', '~', ')', '(', '%', '^', '/', '\\'].each do |sym|
    test "should not save if name has symbol #{sym}" do
      @chan.name = "foo#{sym}bar"
      assert !@chan.save
    end
  end
  
  test "should not save if name is taken" do
    chan2 = Channel.new :name =>'channel', :account_id => @account.id, :kind => 'qst_server', :protocol => 'sms'
    chan2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert chan2.save
    assert !@chan.save
  end
  
  test "should save if name is taken in another account" do
    account2 = Account.create(:name => 'account2', :password => 'foo')
    chan2 = Channel.new :name =>'channel', :account_id => account2.id, :kind => 'qst_server', :protocol => 'sms'
    chan2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert chan2.save
    assert @chan.save
  end
  
  test "should be enabled by default" do
    @chan.save!
    assert @chan.enabled
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
    app1 = create_app @account, '1'
    @chan.application_id = app1.id
    @chan.save!
  
    xml = Hash.from_xml(@chan.to_xml).with_indifferent_access
    chan = xml[:channel]
    assert_equal app1.name, chan[:application]
  end
end
