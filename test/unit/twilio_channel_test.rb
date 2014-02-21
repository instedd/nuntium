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

class TwilioChannelTest < ActiveSupport::TestCase
  def setup
    @chan = new_unsaved_channel
    @chan.save!
  end

  def new_unsaved_channel
    chan = TwilioChannel.make_unsaved
    def chan.configure_phone_number
      self.incoming_password = Devise.friendly_token
      true
    end
    chan
  end

  include GenericChannelTest

  [:account_sid, :auth_token, :from].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "can leave password empty for update" do
    assert_can_leave_password_empty @chan, :auth_token
  end
end
