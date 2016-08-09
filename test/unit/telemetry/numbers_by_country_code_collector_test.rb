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

class Telemetry::NumbersByCountryCodeCollectorTest < ActiveSupport::TestCase

  def setup
    @now = Time.now
    @beginning = @now - 7.days
    @end = @now
    @period = InsteddTelemetry::Period.new beginning: @beginning, end: @end

    @account = Account.make

    AoMessage.make account: @account, to: 'sms://541144445555', created_at: @end - 1.day
    AoMessage.make account: @account, to: 'sms://541144445555', created_at: @end - 10.days
    AoMessage.make account: @account, to: 'sms://541166667777', created_at: @end + 1.day
    AoMessage.make account: @account, to: 'sms://541144445555', created_at: @end - 10.days
    AoMessage.make account: @account, to: 'sms://541144445555', from: 'sms://541188889999', created_at: @end - 15.days

    AoMessage.make account: @account, to: 'sms://85523217391', created_at: @end - 365.days
    AoMessage.make account: @account, to: 'sms://85563337444', created_at: @end + 1.day
    AoMessage.make account: @account, to: 'sms://85523217391', from: 'sms://85564447555', created_at: @end - 7.day

    AtMessage.make account: @account, from: 'sms://541122223333', created_at: @end - 10.days
    AtMessage.make account: @account, from: 'sms://541112345678', created_at: @end + 1.day
    AtMessage.make account: @account, from: 'sms://541122223333', to: 'sms://541167891234', created_at: @end - 10.days

    AtMessage.make account: @account, from: 'sms://85523217391', created_at: @end - 10.days
    AtMessage.make account: @account, from: 'sms://85511111111', created_at: @end + 1.day
    AtMessage.make account: @account, from: 'sms://85523217391', to: 'sms://85522222222', created_at: @end - 10.days
  end

  test 'should collect numbers grouped by country code' do
    stats = Telemetry::NumbersByCountryCodeCollector.collect_stats(@period)

    assert_equal({
      counters: [{
        metric: 'unique_phone_numbers_by_country',
        key: {country_code: '54'},
        value: 2
      }, {
        metric: 'unique_phone_numbers_by_country',
        key: {country_code: '855'},
        value: 1
      }]
    }, stats)
  end

  test 'should not fail if address is null' do
    AoMessage.make account: @account, to: nil, created_at: @end - 1.day

    AtMessage.make account: @account, from: nil, created_at: @end - 1.day

    Telemetry::NumbersByCountryCodeCollector.collect_stats(@period)
  end

end
