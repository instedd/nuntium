require 'test_helper'

class ClickatellChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @chan = Channel.make :clickatell
  end
  
  [:user, :password, :from, :api_id, :incoming_password].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendClickatellMessageJob
  end
  
  test "on enable binds queue" do
    chan = Channel.make_unsaved :clickatell
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end
  
  test "on enable creates worker queue" do
    wqs = WorkerQueue.all(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
    assert_equal 1, wqs.length
    assert_equal 'fast', wqs[0].working_group
    assert_true wqs[0].ack
    assert_true wqs[0].enabled
  end
  
  test "on disable destroys worker queue" do
    @chan.update_attribute :enabled, false
    
    assert_equal 0, WorkerQueue.count(:conditions => ['queue_name = ?', Queues.ao_queue_name_for(@chan)])
  end
  
  test "should use network for channel ao rounting filtering" do
    one = Country.make
    two = Country.make  

    @chan.configuration[:network] = '44'
    @chan.save!  
    ClickatellCoverageMO.create!(
      :country_id => one.id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )
    
    assert @chan.can_route_ao?(ao_with(one.iso2))
    assert_false @chan.can_route_ao?(ao_with(two.iso2))
  end
  
  test "should skip network if channel defines restrictions on country" do
    one = Country.make
    two = Country.make  

    @chan.configuration[:network] = '44'
    @chan.restrictions['country'] = two.id # this overrides clickatell's coverage
    @chan.save!  

    ClickatellCoverageMO.create!(
      :country_id => one.id,
      :carrier_id => nil,
      :network => '44',
      :cost => 1
    )
    
    assert_false @chan.can_route_ao?(ao_with(one.id))
    assert @chan.can_route_ao?(ao_with(two.id))
  end
  
  test "should use network for carrier ao rounting filtering" do
    country = Country.make
    carrier1 = Carrier.make :country => country    
    carrier2 = Carrier.make :country => country

    @chan.configuration[:network] = '44'
    @chan.save!  
       
    ClickatellCoverageMO.create!(
      :country_id => country.id,
      :carrier_id => carrier1.id,
      :network => '44',
      :cost => 1
    )
    
    assert @chan.can_route_ao?(ao_with(country.iso2, carrier1.guid))
    assert_false @chan.can_route_ao?(ao_with(country.iso2, carrier2.guid))
  end
  
  test "should skip network if channel defines restrictions on carrier" do
    country = Country.make
    carrier1 = Carrier.make :country => country    
    carrier2 = Carrier.make :country => country 

    @chan.configuration[:network] = '44'
    @chan.restrictions['carrier'] = carrier2.guid # this overrides clickatell's coverage
    @chan.save!  
       
    ClickatellCoverageMO.create!(
      :country_id => country.id,
      :carrier_id =>  carrier1.id,
      :network => '44',
      :cost => 1
    )
    
    assert_false @chan.can_route_ao?(ao_with(country.iso2, carrier1.guid))
    assert @chan.can_route_ao?(ao_with(country.iso2, carrier2.guid))
  end
  
  def ao_with(country, carrier = nil)
    msg = AOMessage.new
    msg.country = country
    msg.carrier = carrier unless carrier.nil?
    msg
  end
end
