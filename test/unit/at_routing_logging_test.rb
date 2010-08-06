require 'test_helper'

class ATRoutingLoggingTest < ActiveSupport::TestCase

  include RulesEngine

  def setup
    @app = Application.make
    @account = @app.account
    @channel = Channel.make
  end
  
  test "message received via channel" do
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Message received via channel '#{@channel.name}' logged in as '#{@account.name}'"
  end
  
  test "setting channel application" do
    @channel.application = @app
    @channel.save!
  
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Message's application set to '#{@app.name}' because the channel belongs to it"
  end
  
  test "applied at rules" do
    @channel.at_rules = [
        rule(nil,[action('from','sms://5678')])
    ]
    @channel.save!
    
    @msg = ATMessage.make_unsaved :from => 'sms://1234'
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Applying channel at rules..."
    assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
  end
  
  test "save country mobile number information" do
    country = Country.make
  
    @msg = ATMessage.make_unsaved
    @msg.country = country.iso2 
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "The number #{@msg.from.mobile_number} is now associated with country #{country.name} (#{country.iso2}"
  end
  
  test "save carrier mobile number information" do
    carrier = Carrier.make
  
    @msg = ATMessage.make_unsaved
    @msg.carrier = carrier.guid 
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "The number #{@msg.from.mobile_number} is now associated with carrier #{carrier.name} (#{carrier.guid}"
  end
  
  test "inferred country" do
    country = Country.make
  
    @msg = AOMessage.make_unsaved :from => "sms://#{country.phone_prefix}12"
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from prefix"
  end
  
  test "inferred carrier" do
    carrier = Carrier.make
  
    @msg = ATMessage.make_unsaved :from => "sms://#{carrier.country.phone_prefix}#{carrier.prefixes}"
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Carrier #{carrier.name} was inferred from prefix"
  end
  
  test "inferred country from mobile number" do
    country = Country.make  
    @msg = ATMessage.make_unsaved :from => "sms://xx12"    
    MobileNumber.create! :number => @msg.from.mobile_number, :country_id => country.id    
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from mobile numbers table"
  end
  
  test "inferred carrier from mobile number" do
    carrier = Carrier.make
    @msg = ATMessage.make_unsaved :from => "sms://xx12"    
    MobileNumber.create! :number => @msg.from.mobile_number, :carrier_id => carrier.id    
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Carrier #{carrier.name} (#{carrier.guid}) was inferred from mobile numbers table"
  end
  
  test "no application found" do
    @app.destroy
  
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "No application found for routing message"
  end
  
  test "no application was determined" do
    app2 = Application.make :account_id => @app.account_id
    
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "No application was determined. Check application routing rules in account settings"
  end
  
  test "one application" do
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    assert_equal @app.id, @log.application_id
    
    assert_in_log "Message routed to application '#{@app.name}'"
  end
  
  test "account at rules" do
    app2 = Application.make :account_id => @app.account_id
    
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Applying account at rules..."
  end
  
  test "account at rules app not found" do
    app2 = Application.make :account_id => @app.account_id
    
    @account.app_routing_rules= [
        rule(nil,[action('application','foobar')])
    ]
    @account.save!
    
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "Application 'foobar' does not exist"
  end
  
  test "account at rules app found" do
    app2 = Application.make :account_id => @app.account_id
    
    @account.app_routing_rules= [
        rule(nil,[action('application',@app.name)])
    ]
    @account.save!
    
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    assert_equal @app.id, @log.application_id
    
    assert_in_log "Message routed to application '#{@app.name}'"
  end
  
  test "address source created" do
    @msg = ATMessage.make_unsaved
    
    AddressSource.create!(:account_id => @account.id, :application_id => @app.id, :address => @msg.from, :channel_id => @channel.id)
    
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "AddressSource updated with channel '#{@channel.name}'"
  end
  
  test "address source updated" do
    @msg = ATMessage.make_unsaved
    @account.route_at @msg, @channel
    
    @log = check_log
    
    assert_in_log "AddressSource created with channel '#{@channel.name}'"
  end
  
  def assert_in_log(message)
    assert_true @log.message.include?(message) 
  end
  
  def check_log
    logs = AccountLog.all
    assert_equal 1, logs.length
      
    log = logs[0]
    assert_equal @account.id, log.account_id
    assert_equal @channel.id, log.channel_id 
    assert_equal @msg.id, log.at_message_id
    assert_equal AccountLog::Info, log.severity
    
    log
  end
  
end
