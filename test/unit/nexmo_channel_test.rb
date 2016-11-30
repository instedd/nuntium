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

class NexmoChannelTest < ActiveSupport::TestCase
  def setup
    @chan = NexmoChannel.make
  end

  include GenericChannelTest

  [:from, :api_key, :api_secret].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end

  test "can leave api_secret empty for update" do
    assert_can_leave_password_empty @chan, :api_secret
  end

  test "has callback_token" do
    assert @chan.callback_token != nil
  end

  test "more info" do
    msg = AoMessage.new
    msg.custom_attributes["nexmo_status"] = %w(0 1 2)
    msg.custom_attributes["nexmo_remaining_balance"] = %w(1.2 3.4 5.6)
    msg.custom_attributes["nexmo_message_price"] = %w(2.3 4.5 6.7)
    msg.custom_attributes["nexmo_network"] = %w(a b c)

    info = @chan.more_info(msg)
    assert_equal({
      "Nexmo message price 1" => "2.3",
      "Nexmo remaining balance 1" => "1.2",
      "Nexmo network 1" => "a",
      "Nexmo status code 2" => "1",
      "Nexmo error text 2" => "Throttled",
      "Nexmo error meaning 2" => "You have exceeded the submission capacity allowed on this account. Please wait and retry.",
      "Nexmo message price 2" => "4.5",
      "Nexmo remaining balance 2" => "3.4",
      "Nexmo network 2" => "b",
      "Nexmo status code 3" => "2",
      "Nexmo error text 3" => "Missing params",
      "Nexmo error meaning 3" => "Your request is incomplete and missing some mandatory parameters.",
      "Nexmo message price 3" => "6.7",
      "Nexmo remaining balance 3" => "5.6",
      "Nexmo network 3" => "c",
    }, info)
  end
end
