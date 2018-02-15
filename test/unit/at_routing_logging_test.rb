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

class ATRoutingLoggingTest < ActiveSupport::TestCase

  include RulesEngine

  def setup
    @app = Application.make!
    @account = @app.account
    @channel = QstServerChannel.make!
  end

  [false, true].each do |simulate|
    test "message received via channel simulate = #{simulate}" do
      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Message received via channel '#{@channel.name}' logged in as '#{@account.name}'"
    end

    test "setting channel application simulate = #{simulate}" do
      @channel.application = @app
      @channel.save!

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Message's application set to '#{@app.name}' because the channel belongs to it"
    end

    test "applied channel at rules simulate = #{simulate}" do
      @channel.at_rules = [
          rule(nil,[action('from','sms://5678')])
      ]
      @channel.save!

      @msg = AtMessage.make :from => 'sms://1234'
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying channel at rules..."
      assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
    end

    test "applied channel at rules cancels simulate = #{simulate}" do
      @channel.at_rules = [
          rule(nil,[action('cancel','true')])
      ]
      @channel.save!

      @msg = AtMessage.make :from => 'sms://1234'
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying channel at rules..."
      assert_in_log "Message was canceled by channel at rules."
    end

    test "applied app at rules simulate = #{simulate}" do
      @app.at_rules = [
          rule(nil,[action('from','sms://5678')])
      ]
      @app.save!

      @msg = AtMessage.make :from => 'sms://1234'
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying application at rules..."
      assert_in_log "'from' changed from 'sms://1234' to 'sms://5678'"
    end

    test "applied app at rules cancels simulate = #{simulate}" do
      @app.at_rules = [
          rule(nil,[action('cancel','true')])
      ]
      @app.save!

      @msg = AtMessage.make :from => 'sms://1234'
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying application at rules..."
      assert_in_log "Message was canceled by application at rules."
    end

    test "save country mobile number information simulate = #{simulate}" do
      country = Country.make!

      @msg = AtMessage.make
      @msg.country = country.iso2
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "The number #{@msg.from.mobile_number} is now associated with country #{country.name} (#{country.iso2}"
    end

    test "save carrier mobile number information simulate = #{simulate}" do
      carrier = Carrier.make!

      @msg = AtMessage.make
      @msg.carrier = carrier.guid
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "The number #{@msg.from.mobile_number} is now associated with carrier #{carrier.name} (#{carrier.guid}"
    end

    test "inferred country simulate = #{simulate}" do
      country = Country.make!

      @msg = AtMessage.make :from => "sms://#{country.phone_prefix}12"
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from prefix"
    end

    test "inferred carrier simulate = #{simulate}" do
      carrier = Carrier.make!

      @msg = AtMessage.make :from => "sms://#{carrier.country.phone_prefix}#{carrier.prefixes}"
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Carrier #{carrier.name} was inferred from prefix"
    end

    test "inferred country from mobile number simulate = #{simulate}" do
      country = Country.make!
      @msg = AtMessage.make :from => "sms://xx12"
      MobileNumber.create! :number => @msg.from.mobile_number, :country_id => country.id
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Country #{country.name} (#{country.iso2}) was inferred from mobile numbers table"
    end

    test "inferred carrier from mobile number simulate = #{simulate}" do
      carrier = Carrier.make!
      @msg = AtMessage.make :from => "sms://xx12"
      MobileNumber.create! :number => @msg.from.mobile_number, :carrier_id => carrier.id
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Carrier #{carrier.name} (#{carrier.guid}) was inferred from mobile numbers table"
    end

    test "no application found simulate = #{simulate}" do
      @app.destroy

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "No application found for routing message"
    end

    test "no application was determined simulate = #{simulate}" do
      app2 = Application.make! account: @app.account

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "No application was determined. Check application routing rules in account settings"
    end

    test "one application simulate = #{simulate}" do
      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate
      assert_equal @app.id, @log.application_id unless simulate

      assert_in_log "Message routed to application '#{@app.name}'"
    end

    test "account at rules simulate = #{simulate}" do
      app2 = Application.make! :account => @app.account

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Applying account at rules..."
    end

    test "account at rules app not found simulate = #{simulate}" do
      app2 = Application.make! account: @app.account

      @account.app_routing_rules= [
          rule(nil,[action('application','foobar')])
      ]
      @account.save!

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "Application 'foobar' does not exist"
    end

    test "account at rules app found simulate = #{simulate}" do
      app2 = Application.make! account: @app.account

      @account.app_routing_rules= [
          rule(nil,[action('application',@app.name)])
      ]
      @account.save!

      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate
      assert_equal @app.id, @log.application_id unless simulate

      assert_in_log "Message routed to application '#{@app.name}'"
    end

    test "address source created simulate = #{simulate}" do
      @msg = AtMessage.make

      @account.address_sources.create! :application_id => @app.id, :address => @msg.from, :channel_id => @channel.id

      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "AddressSource updated with channel '#{@channel.name}'"
    end

    test "address source updated simulate = #{simulate}" do
      @msg = AtMessage.make
      @account.route_at @msg, @channel, :simulate => simulate

      @log = check_log :simulate => simulate

      assert_in_log "AddressSource created with channel '#{@channel.name}'"
    end
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

    logs = Log.all
    assert_equal 1, logs.length

    log = logs[0]
    assert_equal @account.id, log.account_id
    assert_equal @channel.id, log.channel_id
    assert_equal @msg.id, log.at_message_id
    assert_equal Log::Info, log.severity

    log
  end

end
