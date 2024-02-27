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

class Telemetry::ChannelsByKindCollectorTest < ActiveSupport::TestCase

  def setup
    @now = Time.now
    @beginning = @now - 7.days
    @end = @now
    @period = InsteddTelemetry::Period.new beginning: @beginning, end: @end

    Pop3Channel.make created_at: @end - 3.days
    Pop3Channel.make created_at: @end - 8.days
    Pop3Channel.make created_at: @end + 3.days

    QstClientChannel.make created_at: @end - 1.day
    QstClientChannel.make created_at: @end - 10.days
    QstClientChannel.make created_at: @end - 365.days
    QstClientChannel.make created_at: @end + 1.day
  end

  test 'should collect channels grouped by kind' do
    stats = Telemetry::ChannelsByKindCollector.collect_stats(@period)

    assert_equal({
      counters: [{
        metric: 'channels_by_kind',
        key: {kind: 'pop3'},
        value: 2
      }, {
        metric: 'channels_by_kind',
        key: {kind: 'qst_client'},
        value: 3
      }]
    }, stats)
  end

end
