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

class UserAccountTest < ActiveSupport::TestCase
  
  test "should update account lifespan when created" do
    account = Account.make!
    user_account = UserAccount.make account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    user_account.save
  end

  test "should update account lifespan when updated" do
    account = Account.make!
    user_account = UserAccount.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    user_account.touch
    user_account.save
  end

  test "should update account lifespan when destroyed" do
    account = Account.make!
    user_account = UserAccount.make! account: account

    Telemetry::Lifespan.expects(:touch_account).with(account)

    user_account.destroy
  end

end
