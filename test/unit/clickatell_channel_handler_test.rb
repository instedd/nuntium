require 'test_helper'

class ClickatellChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @account = Account.create(:name => 'account', :password => 'foo')
    @chan = Channel.new(:account_id => @account.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms')
    @chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :from => 'something', :incoming_password => 'incoming_pass' }
  end
  
  [:user, :password, :from, :api_id, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should save" do
    assert @chan.save
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendClickatellMessageJob
  end
  
  test "on enable binds queue" do
    Queues.expects(:bind_ao).with(@chan)
    @chan.save!
  end
  
  test "on enable creates worker queue" do
    @chan.save!
    
    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_equal 1, wqs.length
    assert_equal 'fast', wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "on disable destroys worker queue" do
    @chan.save!
    
    @chan.enabled = false
    @chan.save!
    
    assert_equal 0, WorkerQueue.count(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
  end
  
  test "should use network for channel ao rounting filtering" do
    Country.create!(:name =>'Argentina', :iso2 => 'AR', :iso3 => 'ARG', :phone_prefix => '54')
    Country.create!(:name =>'Armenia', :iso2 => 'AM', :iso3 => 'ARM', :phone_prefix => '374')  

    @chan.configuration[:network] = '44'
    @chan.save!  
    ClickatellCoverageMO.create!(
      :country_id => Country.find_by_iso2('AR').id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )
    
    assert @chan.can_route_ao?(ao_with('AR'))
    assert_false @chan.can_route_ao?(ao_with('AM'))
  end
  
  test "should skip network if channel defines restrictions on country" do
    Country.create!(:name =>'Argentina', :iso2 => 'AR', :iso3 => 'ARG', :phone_prefix => '54')
    Country.create!(:name =>'Armenia', :iso2 => 'AM', :iso3 => 'ARM', :phone_prefix => '374')  

    @chan.configuration[:network] = '44'
    @chan.restrictions['country'] = 'AM' # this overrides clickatell's coverage
    @chan.save!  

    ClickatellCoverageMO.create!(
      :country_id => Country.find_by_iso2('AR').id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )
    
    assert_false @chan.can_route_ao?(ao_with('AR'))
    assert @chan.can_route_ao?(ao_with('AM'))
  end
  
  test "should use network for carrier ao rounting filtering" do
    Country.create!(:name =>'Argentina', :iso2 => 'AR', :iso3 => 'ARG', :phone_prefix => '54')
    Carrier.create!(:country => Country.find_by_iso2('AR'), :name => 'carrier-1', :guid => 'guid-1')    
    Carrier.create!(:country => Country.find_by_iso2('AR'), :name => 'carrier-2', :guid => 'guid-2') 

    @chan.configuration[:network] = '44'
    @chan.save!  
       
    ClickatellCoverageMO.create!(
      :country_id => Country.find_by_iso2('AR').id,
      :carrier_id =>  Carrier.find_by_name('carrier-1').id,
      :network => '44',
      :cost => 1
    )
    
    assert @chan.can_route_ao?(ao_with('AR', 'guid-1'))
    assert_false @chan.can_route_ao?(ao_with('AR', 'guid-2'))
  end
  
  test "should skip network if channel defines restrictions on carrier" do
    Country.create!(:name =>'Argentina', :iso2 => 'AR', :iso3 => 'ARG', :phone_prefix => '54')
    Carrier.create!(:country => Country.find_by_iso2('AR'), :name => 'carrier-1', :guid => 'guid-1')    
    Carrier.create!(:country => Country.find_by_iso2('AR'), :name => 'carrier-2', :guid => 'guid-2') 

    @chan.configuration[:network] = '44'
    @chan.restrictions['carrier'] = Carrier.find_by_name('carrier-2').guid # this overrides clickatell's coverage
    @chan.save!  
       
    ClickatellCoverageMO.create!(
      :country_id => Country.find_by_iso2('AR').id,
      :carrier_id =>  Carrier.find_by_name('carrier-1').id,
      :network => '44',
      :cost => 1
    )
    
    assert_false @chan.can_route_ao?(ao_with('AR', 'guid-1'))
    assert @chan.can_route_ao?(ao_with('AR', 'guid-2'))
  end
  
  def ao_with(country, carrier = nil)
    msg = AOMessage.new
    msg.country = country
    msg.carrier = carrier unless carrier.nil?
    msg
  end
end
