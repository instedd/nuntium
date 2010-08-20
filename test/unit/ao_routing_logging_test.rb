require 'test_helper'

class AORoutingLoggingTest < ActiveSupport::TestCase

  include RulesEngine

  def setup
    @app = Application.make
  end
  
  [false, true].each do |simulate|
    test "message received via interface simulate = #{simulate}" do
      @msg = AOMessage.make_unsaved :to => 'foo'
      @app.route_ao @msg, 'test', :simulate => simulate
       
      @log = check_log :simulate => simulate 
      
      assert_in_log "Received via interface 'test' logged in as '#{@app.account.name}/#{@app.name}'"
    end

    test "protocol not found simulate = #{simulate}" do
      @msg = AOMessage.make_unsaved :to => 'foo'
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Protocol not found in 'to' field"
    end
    
    test "save country mobile number information simulate = #{simulate}" do
      country = Country.make
    
      @msg = AOMessage.make_unsaved
      @msg.country = country.iso2 
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "The number #{@msg.to.mobile_number} is now associated with country #{country.name} (#{country.iso2}"
    end
    
    test "save carrier mobile number information simulate = #{simulate}" do
      carrier = Carrier.make
    
      @msg = AOMessage.make_unsaved
      @msg.carrier = carrier.guid 
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "The number #{@msg.to.mobile_number} is now associated with carrier #{carrier.name} (#{carrier.guid}"
    end
    
    test "inferred country simulate = #{simulate}" do
      country = Country.make
    
      @msg = AOMessage.make_unsaved :to => "sms://#{country.phone_prefix}12"
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from prefix"
    end
    
    test "inferred countries simulate = #{simulate}" do
      country1 = Country.make :phone_prefix => '12'
      country2 = Country.make :phone_prefix => country1.phone_prefix
    
      @msg = AOMessage.make_unsaved :to => "sms://#{country1.phone_prefix}34"
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Country #{country1.name} (#{country1.iso2}) was inferred from prefix"
      assert_in_log "Country #{country2.name} (#{country2.iso2}) was inferred from prefix"
    end
    
    test "inferred carrier simulate = #{simulate}" do
      carrier = Carrier.make
    
      @msg = AOMessage.make_unsaved :to => "sms://#{carrier.country.phone_prefix}#{carrier.prefixes}"
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Carrier #{carrier.name} was inferred from prefix"
    end
    
    test "inferred country from mobile number simulate = #{simulate}" do
      country = Country.make  
      @msg = AOMessage.make_unsaved :to => "sms://xx12"    
      MobileNumber.create! :number => @msg.to.mobile_number, :country_id => country.id    
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from mobile numbers table"
    end
    
    test "inferred carrier from mobile number simulate = #{simulate}" do
      carrier = Carrier.make
      @msg = AOMessage.make_unsaved :to => "sms://xx12"    
      MobileNumber.create! :number => @msg.to.mobile_number, :carrier_id => carrier.id    
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Carrier #{carrier.name} (#{carrier.guid}) was inferred from mobile numbers table"
    end
    
    test "applied application ao rules 1 simulate = #{simulate}" do
      @app.ao_rules = [
          rule(nil,[action('from','sms://5678')])
      ]
      @app.save!
    
      @msg = AOMessage.make_unsaved :from => 'sms://1234'
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Applying application ao rules..."
      assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
    end
    
    test "applied application ao rules 2 simulate = #{simulate}" do
      @app.ao_rules = [
          rule(nil,[action('country','ar')])
      ]
      @app.save!
    
      @msg = AOMessage.make_unsaved
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Applying application ao rules..."
      assert_in_log "'country' changed from '' to 'ar'"
    end
    
    test "channels left after restrictions simulate = #{simulate}" do
      create_channels
      
      @msg = AOMessage.make_unsaved
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Channels left after restrictions: #{@chan1.name}, #{@chan2.name}"
    end
    
    test "suggested channel not in candidates simulate = #{simulate}" do
      create_channels
      
      @msg = AOMessage.make_unsaved
      @msg.suggested_channel = @chan3.name
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Suggested channel '#{@msg.suggested_channel}' not found in candidates"
    end
    
    test "suggested channel in candidates simulate = #{simulate}" do
      create_channels
      
      @msg = AOMessage.make_unsaved
      @msg.suggested_channel = @chan1.name
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Suggested channel '#{@msg.suggested_channel}' found in candidates"
    end
    
    test "known address sources simulate = #{simulate}" do
      create_channels
      
      @msg = AOMessage.make_unsaved
      
      AddressSource.create! :address => @msg.to, :channel_id => @chan1.id, :updated_at => (Time.now - 10), :account_id => @app.account_id, :application_id => @app.id 
      AddressSource.create! :address => @msg.to, :channel_id => @chan2.id, :account_id => @app.account_id, :application_id => @app.id
      
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Address sources are: #{@chan2.name}, #{@chan1.name}"
    end
    
    test "selected from address sources simulate = #{simulate}" do
      create_channels
      
      @msg = AOMessage.make_unsaved
      
      AddressSource.create! :address => @msg.to, :channel_id => @chan1.id, :updated_at => (Time.now - 10), :account_id => @app.account_id, :application_id => @app.id 
      AddressSource.create! :address => @msg.to, :channel_id => @chan2.id, :account_id => @app.account_id, :application_id => @app.id
      
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "'#{@chan2.name}' selected from address sources"
    end
    
    test "no suitable channel simulate = #{simulate}" do
      @msg = AOMessage.make_unsaved
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "No suitable channel found for routing the message"
    end
    
    test "routed to channel simulate = #{simulate}" do
      create_channels 1
    
      @msg = AOMessage.make_unsaved
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      if not simulate
        assert_equal @chan1.id, @log.channel_id
      end
      
      assert_in_log "Message routed to channel '#{@chan1.name}'"
    end
    
    test "applied channel ao rules simulate = #{simulate}" do
      create_channels 1
      @chan1.ao_rules = [
          rule(nil,[action('from','sms://5678')])
      ]
      @chan1.save!
      
      @msg = AOMessage.make_unsaved :from => 'sms://1234'
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "Applying channel ao rules..."
      assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
    end
    
    test "many channels with same priority simulate = #{simulate}" do
      create_channels 2
      
      @msg = AOMessage.make_unsaved
      @app.route_ao @msg, 'test', :simulate => simulate
      
      @log = check_log :simulate => simulate
      
      assert_in_log "All these channels have the same priority: #{@chan1.name}, #{@chan2.name}"
    end
    
    test "strategy override simulate = #{simulate}" do
      create_channels 2
    
      @msg = AOMessage.make_unsaved
      @msg.strategy = 'broadcast'
      result = @app.route_ao @msg, 'test', :simulate => simulate
      
      if simulate
        assert_equal 'broadcast', result[:strategy]
        logs = result[:logs]
        assert_equal 3, logs.length
        assert_true logs[0].include? "Strategy overwritten by message to 'broadcast'" 
      else
        @log = AccountLog.first :conditions => "ao_message_id = #{@msg.id}"
        check_log :log => @log
        assert_in_log "Strategy overwritten by message to 'broadcast'"
      end
    end
    
    test "broadcast simulate = #{simulate}" do
      create_channels 2
      
      @chan1.ao_rules = [
          rule(nil,[action('from','sms://5678')])
      ]
      @chan1.save!
      
      @chan2.ao_rules = [
          rule(nil,[action('from','sms://8765')])
      ]
      @chan2.save!
    
      @msg = AOMessage.make_unsaved :from => 'sms://1234'
      @msg.strategy = 'broadcast'
      result = @app.route_ao @msg, 'test', :simulate => simulate
      
      if simulate
        assert_equal 'broadcast', result[:strategy]
        logs = result[:logs]
        assert_equal 3, logs.length
        
        assert_true logs[1].include? "Applying channel ao rules..."
        assert_true logs[1].include? "'from' changed from 'sms://1234' to 'sms://5678'"
        
        assert_true logs[2].include? "Applying channel ao rules..."
        assert_true logs[2].include? "'from' changed from 'sms://1234' to 'sms://8765'"
      else
        copies = AOMessage.all :conditions => "parent_id = #{@msg.id}"
        
        @msg = copies[0]
        @log = AccountLog.first :conditions => "ao_message_id = #{@msg.id}"
        check_log :log => @log
        assert_equal @chan1.id, @log.channel_id
        
        assert_in_log "Applying channel ao rules..."
        assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
        
        @msg = copies[1]
        @log = AccountLog.first :conditions => "ao_message_id = #{@msg.id}"
        check_log :log => @log
        assert_equal @chan2.id, @log.channel_id
        
        assert_in_log "Applying channel ao rules..."
        assert_in_log "'from' changed from 'sms://1234' to 'sms://8765'"
      end
    end
  end
  
  def create_channels(ammount = 3)
    @chan1 = Channel.make :account_id => @app.account_id, :protocol => 'sms' if ammount >= 1
    @chan2 = Channel.make :account_id => @app.account_id, :protocol => 'sms' if ammount >= 2
    @chan3 = Channel.make :account_id => @app.account_id, :protocol => 'foo' if ammount >= 3
  end
  
  def assert_in_log(message)
    assert_true @log.message.include?(message) 
  end
  
  def check_log(options = {})
    if options[:simulate]
      msg = ThreadLocalLogger.result
      log = mock('log')
      log.stubs :message => msg
      return log
    end
  
    if options[:log]
      log = options[:log]
    else
      logs = AccountLog.all
      assert_equal 1, logs.length
      
      log = logs[0]
    end
    assert_equal @app.account_id, log.account_id
    assert_equal @app.id, log.application_id
    assert_equal @msg.id, log.ao_message_id
    assert_equal AccountLog::Info, log.severity
    
    log
  end
end
