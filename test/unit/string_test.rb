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

class StringTest < ActiveSupport::TestCase
  test "to.protocol" do
    msg = AoMessage.new(:to => 'sms://something')
    assert_equal 'sms', msg.to.protocol
  end

  test "to.protocol nil" do
    msg = AoMessage.new(:to => 'something')
    assert_equal '', msg.to.protocol
  end

  test "to.without_protocol nil" do
    msg = AoMessage.new(:to => 'sms://something')
    assert_equal 'something', msg.to.without_protocol
  end

  test "from.protocol" do
    msg = AoMessage.new(:from => 'sms://something')
    assert_equal 'sms', msg.from.protocol
  end

  test "from.protocol nil" do
    msg = AoMessage.new(:from => 'something')
    assert_equal '', msg.from.protocol
  end

  test "from.without_protocol nil" do
    msg = AoMessage.new(:from => 'sms://something')
    assert_equal 'something', msg.from.without_protocol
  end

  test "starts with" do
    assert 'HolaATodos'.starts_with?('Hola')
    assert !'HolaATodos'.starts_with?('HolaT')
  end

  test "mobile_number" do
    assert_equal '1234', 'sms://1234'.mobile_number
    assert_equal '1234', 'sms://+1234'.mobile_number
    assert_equal '1234', '+1234'.mobile_number
  end

  test "protocol and address" do
    assert_equal ['sms', '1234'], 'sms://1234'.protocol_and_address
    assert_equal ['', '1234'], '1234'.protocol_and_address
    assert_equal ['sms', ''], 'sms://'.protocol_and_address
  end

  test "valid sms address" do
    assert "sms://1234".valid_address?
    assert "sms://+1234".valid_address?
    assert !"sms://foo".valid_address?
    assert !"sms://+foo".valid_address?
    assert !"sms://".valid_address?
    assert !"sms:// ".valid_address?
    assert !"sms:// 123".valid_address?
    assert !"sms://123 4".valid_address?
  end

  test "valid email address" do
    assert "mailto://foo@bar.com".valid_address?
    assert "mailto://foo.bar+baz@example.com".valid_address?
    assert !"mailto://foo".valid_address?
    assert !"mailto://!()@foo.com".valid_address?
    assert !"mailto://%$\#@foo.com".valid_address?
    assert !"mailto://".valid_address?
    assert !"mailto:// ".valid_address?
    assert !"mailto:// foo@bar.com".valid_address?
  end

  test "sanitize" do
    string = "hello#{(0..0x1F).map{|x| x.chr}.join}world"
    string.sanitize!
    assert_equal "hello??????????\n??\r??????????????????world", string
  end

end
