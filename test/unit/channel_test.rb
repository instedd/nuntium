require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make
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
    chan2 = Channel.make_unsaved :name => @chan.name, :account => @chan.account
    assert_false chan2.save
  end
  
  test "should save if name is taken in another account" do
    account2 = Account.make
    chan2 = Channel.make_unsaved :name => @chan.name, :account => account2
    assert chan2.save
  end
  
  test "should be enabled by default" do
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
end
