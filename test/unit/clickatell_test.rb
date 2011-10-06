require "test_helper"

class ClickatellTest < ActiveSupport::TestCase

  def setup
    @usa = Country.make :name => 'USA', :iso2 => 'US'

    @arg = Country.make :name => 'Argentina', :clickatell_name => 'Argentina'
    @aus = Country.make :name => 'Australia', :clickatell_name => 'Australia'

    @amx = Carrier.make :name => 'AMX(Claro)', :clickatell_name => 'AMX(Claro)', :country => @arg
    @nex = Carrier.make :name => 'Nextel (iDEN)', :clickatell_name => 'Nextel (iDEN)', :country => @arg
    @tel = Carrier.make :name => 'Telstra', :clickatell_name => 'Telstra', :country => @aus

    @s = <<-EOF
Country, Country Code, Network, +41,+44 [A] *,+46,+61,+49,+45,+44 [B]
"Argentina","54"
,,"AMX(Claro)","1","2","3","4","x","x","x"
,,"Nextel (iDEN)","5","6","7","x","x","x","x"
"Australia","61"
,,"Telstra","x","8","x","9","x","10","11"
EOF

    RestClient.expects(:get).with("http://www.clickatell.com/pricing/standard_mo_coverage.php?action=export&country=").returns(@s)
  end

  test "create coverage tables" do
    update_coverage_tables
  end

  test "update coverage tables" do
    ClickatellCoverageMO.create! :country_id => @arg.id, :carrier_id => @amx.id, :network => '44a', :cost => 10
    ClickatellCoverageMO.create! :country_id => @arg.id, :carrier_id => @amx.id, :network => '46', :cost => 20

    update_coverage_tables
  end

  test "clears cache" do
    ClickatellCoverageMO.create! :country_id => @arg.id, :carrier_id => @amx.id, :network => '44a', :cost => 10

    chan = ClickatellChannel.make
    chan.configuration[:network] = '44a'
    chan.save!

    chan.augmented_restrictions

    assert_not_nil Rails.cache.read(chan.restrictions_cache_key)

    update_coverage_tables

    assert_nil Rails.cache.read(chan.restrictions_cache_key)
  end

  def update_coverage_tables
    Clickatell.update_coverage_tables :silent => true

    coverages = ClickatellCoverageMO.all
    assert_equal 10, coverages.length

    [
      [@arg.id, @amx.id, '44a', 2],
      [@arg.id, @amx.id, '46', 3],
      [@arg.id, @amx.id, '61', 4],
      [@arg.id, @nex.id, '44a', 6],
      [@arg.id, @nex.id, '46', 7],
      [@aus.id, @tel.id, '44a', 8],
      [@aus.id, @tel.id, '61', 9],
      [@aus.id, @tel.id, '45', 10],
      [@aus.id, @tel.id, '44b', 11],
      [@usa.id, nil, 'usa', 1]
    ].each do |country_id, carrier_id, network, cost|
      assert_true coverages.any? do |x|
        x.country_id == country_id && x.carrier_id == carrier_id && x.network == network && x.cost == cost
      end
    end
  end

end
