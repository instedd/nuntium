# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

require 'test_helper'

class AORoutingLoggingTest < ActiveSupport::TestCase

  include RulesEngine

  def setup
    @app = Application.make!
  end

  [false, true].each do |simulate|
    test "message received via interface simulate = #{simulate}" do
      @msg = AoMessage.make :to => 'foo'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Received via test interface logged in as '#{@app.account.name}/#{@app.name}'"
    end

    test "protocol not found simulate = #{simulate}" do
      @msg = AoMessage.make :to => 'foo'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Protocol not found in 'to' field"
    end

    test "save country mobile number information simulate = #{simulate}" do
      country = Country.make!

      @msg = AoMessage.make
      @msg.country = country.iso2
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "The number #{@msg.to.mobile_number} is now associated with country #{country.name} (#{country.iso2}"
    end

    test "save carrier mobile number information simulate = #{simulate}" do
      carrier = Carrier.make!

      @msg = AoMessage.make
      @msg.carrier = carrier.guid
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "The number #{@msg.to.mobile_number} is now associated with carrier #{carrier.name} (#{carrier.guid}"
    end

    test "inferred country simulate = #{simulate}" do
      country = Country.make!

      @msg = AoMessage.make :to => "sms://#{country.phone_prefix}12"
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from prefix"
    end

    test "inferred countries simulate = #{simulate}" do
      country1 = Country.make! :phone_prefix => '12'
      country2 = Country.make! :phone_prefix => country1.phone_prefix

      @msg = AoMessage.make :to => "sms://#{country1.phone_prefix}34"
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Country #{country1.name} (#{country1.iso2}) was inferred from prefix"
      assert_in_log "Country #{country2.name} (#{country2.iso2}) was inferred from prefix"
    end

    test "inferred carrier simulate = #{simulate}" do
      carrier = Carrier.make!

      @msg = AoMessage.make :to => "sms://#{carrier.country.phone_prefix}#{carrier.prefixes}"
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Carrier #{carrier.name} was inferred from prefix"
    end

    test "inferred country from mobile number simulate = #{simulate}" do
      country = Country.make!
      @msg = AoMessage.make :to => "sms://xx12"
      MobileNumber.create! :number => @msg.to.mobile_number, :country_id => country.id
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from mobile numbers table"
    end

    test "inferred carrier from mobile number simulate = #{simulate}" do
      carrier = Carrier.make!
      @msg = AoMessage.make :to => "sms://xx12"
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

      @msg = AoMessage.make :from => 'sms://1234'
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

      @msg = AoMessage.make
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying application ao rules..."
      assert_in_log "'country' changed from '' to 'ar'"
    end

    test "applied application ao rules cancels simulate = #{simulate}" do
      @app.ao_rules = [
          rule(nil,[action('cancel','true')])
      ]
      @app.save!

      @msg = AoMessage.make :from => 'sms://1234'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying application ao rules..."
      assert_in_log "Message was canceled by application ao rules."
    end

    test "channels left after restrictions simulate = #{simulate}" do
      create_channels

      @msg = AoMessage.make
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Channels left after restrictions: #{@chan1.name}, #{@chan2.name}"
    end

    test "suggested channel not in candidates simulate = #{simulate}" do
      create_channels

      @msg = AoMessage.make
      @msg.suggested_channel = @chan3.name
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Suggested channel '#{@msg.suggested_channel}' not found in candidates"
    end

    test "suggested channel in candidates simulate = #{simulate}" do
      create_channels

      @msg = AoMessage.make
      @msg.suggested_channel = @chan1.name
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Suggested channel '#{@msg.suggested_channel}' found in candidates"
    end

    test "known address sources simulate = #{simulate}" do
      create_channels

      @msg = AoMessage.make

      AddressSource.create! :address => @msg.to, :channel_id => @chan1.id, :updated_at => (Time.now - 10), :account_id => @app.account_id, :application_id => @app.id
      AddressSource.create! :address => @msg.to, :channel_id => @chan2.id, :account_id => @app.account_id, :application_id => @app.id

      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Address sources are: #{@chan2.name}, #{@chan1.name}"
    end

    test "selected from address sources simulate = #{simulate}" do
      create_channels

      @msg = AoMessage.make

      AddressSource.create! :address => @msg.to, :channel_id => @chan1.id, :updated_at => (Time.now - 10), :account_id => @app.account_id, :application_id => @app.id
      AddressSource.create! :address => @msg.to, :channel_id => @chan2.id, :account_id => @app.account_id, :application_id => @app.id

      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "'#{@chan2.name}' selected from address sources"
    end

    test "no suitable channel simulate = #{simulate}" do
      @msg = AoMessage.make
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "No suitable channel found for routing the message"
    end

    test "routed to channel simulate = #{simulate}" do
      create_channels 1

      @msg = AoMessage.make
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

      @msg = AoMessage.make :from => 'sms://1234'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying channel ao rules..."
      assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
    end

    test "applied channel ao rules cancels simulate = #{simulate}" do
      create_channels 1
      @chan1.ao_rules = [
          rule(nil,[action('cancel','true')])
      ]
      @chan1.save!

      @msg = AoMessage.make :from => 'sms://1234'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying channel ao rules..."
      assert_in_log "Message was canceled by channel ao rules."
    end

    test "strategy override simulate = #{simulate}" do
      create_channels 2

      @msg = AoMessage.make
      @msg.strategy = 'broadcast'
      result = @app.route_ao @msg, 'test', :simulate => simulate

      if simulate
        assert_equal 'broadcast', result[:strategy]
        logs = result[:logs]
        assert_equal 3, logs.length
        assert_true logs[0].include? "Strategy overwritten by message to 'broadcast'"
      else
        @log = @msg.logs.first
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

      @msg = AoMessage.make :from => 'sms://1234'
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
        copies = @msg.children

        @msg = copies[0]
        @log = @msg.logs.first
        check_log :log => @log
        assert_equal @chan1.id, @log.channel_id

        assert_in_log "Applying channel ao rules..."
        assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"

        @msg = copies[1]
        @log = @msg.logs.first
        check_log :log => @log
        assert_equal @chan2.id, @log.channel_id

        assert_in_log "Applying channel ao rules..."
        assert_in_log "'from' changed from 'sms://1234' to 'sms://8765'"
      end
    end

    test "message 'from' and 'to' are the same simulate = #{simulate}" do
      create_channels 1

      @msg = AoMessage.make :from => 'sms://1', :to => 'sms://1'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate, :severity => Log::Warning

      assert_in_log "Message 'from' and 'to' addresses are the same. The message will be discarded."
    end

    test "message 'to' is invalid simulate = #{simulate}" do
      create_channels 1

      @msg = AoMessage.make :to => 'sms://hello'
      @app.route_ao @msg, 'test', :simulate => simulate

      @log = check_log :simulate => simulate, :severity => Log::Warning

      assert_in_log "Message 'to' address is invalid. The message will be discarded."
    end
  end

  def create_channels(ammount = 3)
    @chan1 = QstServerChannel.make! :account_id => @app.account_id, :name => 'channel1', :protocol => 'sms' if ammount >= 1
    @chan2 = QstServerChannel.make! :account_id => @app.account_id, :name => 'channel2', :protocol => 'sms' if ammount >= 2
    @chan3 = QstServerChannel.make! :account_id => @app.account_id, :name => 'channel3', :protocol => 'foo' if ammount >= 3
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
      logs = Log.all
      assert_equal 1, logs.length

      log = logs[0]
    end
    assert_equal @app.account_id, log.account_id
    assert_equal @app.id, log.application_id
    assert_equal @msg.id, log.ao_message_id
    assert_equal (options[:severity] || Log::Info), log.severity

    log
  end
end
