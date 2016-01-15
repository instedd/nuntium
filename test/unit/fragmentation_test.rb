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

class FragmentationTest < ActiveSupport::TestCase
  def setup
    @account = Account.make! :password => 'secret1'
    @app = Application.make! account: @account, password: 'secret2'
    @chan = QstServerChannel.make! :account => @account
  end

  # Fragment format is:
  #
  #   &&XXXTNNN|...|
  #   1234567..8...9
  #
  # That is, at least 9 chars are lost.

  test "fragment id base on AoMessage id" do
    assert_equal "n7W", AoMessage.fragment_id(88904)
  end

  test "build fragments" do
    body = ("Hello world. This is a relly long message." * 1000).strip
    compressed = Zlib::Deflate.deflate(body)
    base64 = Base64.strict_encode64(compressed).strip

    ao = AoMessage.make! account: @account, application: @app, to: "sms://1234", body: body
    ao.fragment = true

    first_base64 = base64[0 ... 131]
    second_base64 = base64[131 .. -1]

    first_packet = "&&A#{ao.fragment_id}0|#{first_base64}|"
    second_packet = "&&B#{ao.fragment_id}1|#{second_base64}|"

    fragments = ao.build_fragments
    assert_equal 2, fragments.length

    assert_equal first_packet, fragments[0].body
    assert_equal ao.to, fragments[0].to
    assert_equal "pending", fragments[0].state
    assert_equal ao.id, fragments[0].parent_id
    assert_nil fragments[0].fragment

    assert_equal second_packet, fragments[1].body
    assert_equal ao.to, fragments[1].to
    assert_equal "pending", fragments[1].state
    assert_equal ao.id, fragments[1].parent_id
    assert_nil fragments[1].fragment
  end

  test "send fragmented message" do
    body = ("Hello world. This is a relly long message. " * 1000).strip
    compressed = Zlib::Deflate.deflate(body)
    base64 = Base64.strict_encode64(compressed).strip

    first_base64 = base64[0 ... 131]
    second_base64 = base64[131 .. -1]

    msg = AoMessage.make to: "sms://1234", body: body
    msg.fragment = true

    @app.route_ao msg, 'test'

    first_packet = "&&A#{msg.fragment_id}0|#{first_base64}|"
    second_packet = "&&B#{msg.fragment_id}1|#{second_base64}|"

    msgs = AoMessage.all
    assert_equal 3, msgs.length

    assert_equal body, msgs[0].body
    assert_true msgs[0].fragment

    assert_equal first_packet, msgs[1].body
    assert_equal msgs[0].id, msgs[1].parent_id

    assert_equal second_packet, msgs[2].body
    assert_equal msgs[0].id, msgs[2].parent_id

    fragments = AoMessageFragment.all
    assert_equal 2, fragments.length

    assert_equal @account.id, fragments[0].account_id
    assert_equal @chan.id, fragments[0].channel_id
    assert_equal msgs[1].id, fragments[0].ao_message_id
    assert_equal msg.fragment_id, fragments[0].fragment_id
    assert_equal 0, fragments[0].number

    assert_equal @account.id, fragments[1].account_id
    assert_equal @chan.id, fragments[1].channel_id
    assert_equal msgs[2].id, fragments[1].ao_message_id
    assert_equal msg.fragment_id, fragments[1].fragment_id
    assert_equal 1, fragments[1].number
  end

  test "don't send fragmented message if length is less or equal than then maximum" do
    body = "a" * MessageFragmentation::MAX_MESSAGE_LENGTH

    msg = AoMessage.make to: "sms://1234", body: body
    msg.fragment = true

    @app.route_ao msg, 'test'

    assert_equal 1, AoMessage.count
  end

  test "resend some fragments" do
    body = ("Hello world. This is a relly long message. " * 2000).strip

    ao = AoMessage.make to: "sms://1234", body: body
    ao.fragment = true

    @app.route_ao ao, 'test'

    msgs = AoMessage.all
    assert_equal 5, msgs.length

    msgs[1 .. -1].each do |piece|
      piece.state = "delivered"
      piece.save!
    end

    at = AtMessage.make from: "sms://1234", body: "&&C#{ao.fragment_id}0,2,3"
    @account.route_at at, @chan

    at.reload

    assert_not_nil at.id

    msgs.each &:reload

    assert_equal "queued", msgs[1].state
    assert_equal "delivered", msgs[2].state
    assert_equal "queued", msgs[3].state
    assert_equal "queued", msgs[4].state
  end

  test "ack" do
    body = ("Hello world. This is a relly long message. " * 1000).strip

    ao = AoMessage.make to: "sms://1234", body: body
    ao.fragment = true

    @app.route_ao ao, 'test'

    at = AtMessage.make from: "sms://1234", body: "&&D#{ao.fragment_id}"
    @account.route_at at, @chan

    at.reload

    assert_not_nil at.id

    ao.reload
    assert_equal "confirmed", ao.state
  end
end
