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

class Telemetry::LifespanTest < ActiveSupport::TestCase

  def setup
    @now = Time.now
    @from = @now - 1.week

    Timecop.freeze(@now)
  end

  def teardown
    Timecop.return
  end

  test 'updates the application lifespan' do
    application = Application.make created_at: @from

    InsteddTelemetry.expects(:timespan_update).with('application_lifespan', {application_id: application.id}, application.created_at, @now)

    Telemetry::Lifespan.touch_application application
  end

  test 'updates the account lifespan' do
    account = Account.make created_at: @from

    InsteddTelemetry.expects(:timespan_update).with('account_lifespan', {account_id: account.id}, account.created_at, @now)

    Telemetry::Lifespan.touch_account account
  end

end
