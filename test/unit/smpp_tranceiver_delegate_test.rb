# coding: utf-8

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
require 'smpp'

class SmppTranceiverDelegateTest < ActiveSupport::TestCase
  def setup
    @chan = SmppChannel.make_unsaved
    @transceiver = mock('Smpp::Transceiver')
  end

  def convert_optional_parameters(optional_parameters)
    optionals = {}
    optional_parameters.each do |x, y|
      optionals[x] = Smpp::OptionalParameter.new(x, y)
    end
    optionals
  end

  def send_message(encodings, input, output, output_coding, options = {})
    @chan.configuration[:mt_encodings] = encodings
    @chan.configuration[:endianness_mt] = options.fetch(:endianness_mt, :big).to_s
    @chan.configuration[:default_mo_encoding] = 'ascii'
    @chan.configuration[:mt_csms_method] = options.fetch(:mt_csms_method, 'udh')
    @chan.configuration[:mt_max_length] = options.fetch(:mt_max_length, 254)
    @chan.configuration[:service_type] = options[:service_type]
    @chan.save!

    if output.is_a? String
      output = [{:text => output}]
    end

    output.each do |o|
      expect_options = { :data_coding => output_coding }
      expect_options[:service_type] = options[:service_type] if options[:service_type].present?
      if o.include? :udh
        expect_options[:udh] = o[:udh]
        expect_options[:esm_class] = 64
      end
      if o.include? :optional_parameters
        expect_options[:optional_parameters] = convert_optional_parameters(o[:optional_parameters])
      end
      @transceiver.expects(:send_mt).with(123, '8888', '4444', o[:text], expect_options)
    end

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    if options.include? :send_options
      @delegate.send_message(123, '8888', '4444', input, options[:send_options])
    else
      @delegate.send_message(123, '8888', '4444', input)
    end
  end

  def receive_message(input, input_coding, output, options = {})
    @chan.configuration[:mt_encodings] = ['ascii']
    @chan.configuration[:endianness_mo] = options.fetch(:endianness_mo, :big).to_s
    @chan.configuration[:default_mo_encoding] = options.fetch(:default_mo_encoding, 'ascii')
    @chan.configuration[:mt_csms_method] = 'udh'
    @chan.configuration[:accept_mo_hex_string] = options.fetch(:accept_mo_hex_string, false) ? '1' : '0'
    @chan.save!
    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)

    pdu_options = {:data_coding => input_coding}
    pdu_options[:esm_class] = options[:esm_class] if options.include? :esm_class
    if options.include? :optional_parameters
      optionals = convert_optional_parameters options[:optional_parameters]
      pdu_options[:optional_parameters] = optionals
    end

    from = options.fetch(:from, '4444')
    pdu = Smpp::Pdu::DeliverSm.new from, '8888', input, pdu_options
    @delegate.mo_received @transceiver, pdu

    if options.fetch(:part, false)
      part = SmppMessagePart.last
      assert_not_nil part
      assert_equal @chan.id, part.channel_id
      assert_equal options[:reference_number], part.reference_number
      assert_equal options[:part_count], part.part_count
      assert_equal options[:part_number], part.part_number
      assert_equal from, part.source
      assert_equal output, part.text
    else
      msgs = AtMessage.all
      assert_equal 1, msgs.length
      msg = msgs[0]
      assert_equal "sms://#{from}", msg.from
      assert_equal 'sms://8888', msg.to
      assert_equal output, msg.body
      assert_equal @chan.id, msg.channel_id
    end
  end

  def assert_delivery_report(channel_relative_id, state, optional_parameters = {})
    save_channel_with_default_config

    msg = AoMessage.create! :account => @chan.account, :channel => @chan, :channel_relative_id => "#{channel_relative_id}"
    pdu = Smpp::Pdu::DeliverSm.new '4444', '8888', 'hola', optional_parameters

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.delivery_report_received @transceiver, pdu

    msg = AoMessage.find_by_id msg.id
    assert_equal state, msg.state

    logs = Log.all
    assert_equal 1, logs.length

    if optional_parameters[:message_state]
      assert_equal "#{optional_parameters[:message_state]} received from server", logs[0].message
    elsif optional_parameters[:stat]
      assert_equal "#{optional_parameters[:stat]} received from server", logs[0].message
    end
  end

  def assert_message_accepted_with_delivery_receipt(pdu_submit_sm_response_bin, pdu_deliver_sm_bin)
    save_channel_with_default_config

    pdu_submit_sm_response = Smpp::Pdu::Base.create(pdu_submit_sm_response_bin.scan(/../).map{|x| x.to_i(16).chr}.join)
    pdu_deliver_sm = Smpp::Pdu::Base.create(pdu_deliver_sm_bin.scan(/../).map{|x| x.to_i(16).chr}.join)

    msg = AoMessage.create! :account => @chan.account, :channel => @chan

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)

    @delegate.message_accepted @transceiver, msg.id, pdu_submit_sm_response
    assert_equal 'delivered', AoMessage.find_by_id(msg.id).state

    @delegate.delivery_report_received @transceiver, pdu_deliver_sm
    assert_equal 'confirmed', AoMessage.find_by_id(msg.id).state
  end

  def save_channel_with_default_config
    @chan.configuration[:mt_encodings] = ['ascii']
    @chan.configuration[:endianness_mo] = 'big'
    @chan.configuration[:endianness_mt] = 'big'
    @chan.configuration[:default_mo_encoding] = 'ascii'
    @chan.configuration[:mt_csms_method] = 'udh'
    @chan.configuration[:mt_max_length] = 254
    @chan.save!
  end

  test "send ascii message" do
    send_message ['ascii'], 'Hello', 'Hello', 1
  end

  test "send message with custom service type" do
    send_message ['ascii'], 'Hello', 'Hello', 1, :service_type => 'foo'
  end

  test "send ascii message as latin1" do
    send_message ['latin1'], 'Hello', 'Hello', 3
  end

  test "send ascii message as ascii" do
    send_message ['ascii', 'latin1'], 'Hello', 'Hello', 1
  end

  test "send latin1 message as latin1" do
    send_message ['ascii', 'latin1'], 'árbol', "\341rbol".force_encoding('ASCII-8BIT'), 3
  end

  test "send ascii message as ucs2" do
    send_message ['ucs-2'], 'hola', "\000h\000o\000l\000a".force_encoding('UTF-16BE'), 8
  end

  test "send unicode message as ucs2" do
    send_message ['ascii', 'latin1', 'ucs-2'], "你好", "\117\140\131\175".force_encoding('UTF-16BE'), 8
  end

  test "send ucs2 little endian" do
    send_message ['ucs-2'], 'hola', "h\000o\000l\000a\000", 8, :endianness_mt => :little
  end

  test "send large message using udh" do
    output = [
      {:udh => "\x05\x00\x03\x7B\x04\x01", :text => 'uno'},
      {:udh => "\x05\x00\x03\x7B\x04\x02", :text => 'dos'},
      {:udh => "\x05\x00\x03\x7B\x04\x03", :text => 'tre'},
      {:udh => "\x05\x00\x03\x7B\x04\x04", :text => 's'}
      ]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'udh', :mt_max_length => 9
  end

  test "send large message using SAR optional parameters" do
    output = [
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x01"}, :text => 'uno'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x02"}, :text => 'dos'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x03"}, :text => 'tre'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x04"}, :text => 's'}
      ]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'optional_parameters', :mt_max_length => 3
  end

  test "send large message using message payload" do
    output = [{:text => '', :optional_parameters => { 0x0424 => 'unodostres' }}]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'message_payload', :mt_max_length => 3
  end

  test "send duplicate message is not ignored" do
    save_channel_with_default_config

    pdu = Smpp::Pdu::DeliverSm.new '4444', '8888', 'hola'

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.mo_received @transceiver, pdu
    @delegate.mo_received @transceiver, pdu

    assert_equal 2, AtMessage.count
  end

  test "send message with custom options" do
    output = [{:text => 'Hello', :optional_parameters => { 0x1234 => 'foo' }}]
    send_message ['ascii'], 'Hello', output, 1, :send_options => { 0x1234 => 'foo' }
  end

  test "send large message with udh and custom options" do
    output = [
      {:udh => "\x05\x00\x03\x7B\x04\x01", :text => 'uno', :optional_parameters => { 0x1234 => 'foo' }},
      {:udh => "\x05\x00\x03\x7B\x04\x02", :text => 'dos', :optional_parameters => { 0x1234 => 'foo' }},
      {:udh => "\x05\x00\x03\x7B\x04\x03", :text => 'tre', :optional_parameters => { 0x1234 => 'foo' }},
      {:udh => "\x05\x00\x03\x7B\x04\x04", :text => 's', :optional_parameters => { 0x1234 => 'foo' }}
      ]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'udh', :mt_max_length => 9, :send_options => { 0x1234 => 'foo' }
  end

  test "send large message with optional parameters and custom options" do
    output = [
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x01", 0x1234 => 'foo'}, :text => 'uno'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x02", 0x1234 => 'foo'}, :text => 'dos'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x03", 0x1234 => 'foo'}, :text => 'tre'},
      {:optional_parameters => { 0x020c => "\x00\x7b", 0x020e =>  "\x04", 0x020f => "\x04", 0x1234 => 'foo'}, :text => 's'}
      ]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'optional_parameters', :mt_max_length => 3, :send_options => { 0x1234 => 'foo' }
  end

  test "send large message using message payload and custom options" do
    output = [{:text => '', :optional_parameters => { 0x0424 => 'unodostres', 0x1234 => 'foo' }}]
    send_message ['ascii'], 'unodostres', output, 1, :mt_csms_method => 'message_payload', :mt_max_length => 3, :send_options => { 0x1234 => 'foo' }
  end

  test "receive ascii message" do
    receive_message 'hello', 1, 'hello'
  end

  test "receive latin1 message" do
    receive_message "\341rbol".force_encoding('ASCII-8BIT'), 3, 'árbol'
  end

  test "receive ucs2 message" do
    receive_message "\000h\000o\000l\000a", 8, 'hola'
  end

  test "receive usc2-le message" do
    receive_message "h\000o\000l\000a\000", 8, 'hola', :endianness_mo => :little
  end

  test "receive default encoding message" do
    receive_message "h\000o\000l\000a\000", 0, 'hola', :endianness_mo => :little, :default_mo_encoding => 'ucs-2'
  end

  test "receive gsm message as default" do
    receive_message "\x0", 0, '@', :default_mo_encoding => 'gsm'
  end

  test "receive hex string" do
    receive_message "006100620063", 0, 'abc', :accept_mo_hex_string => true
  end

  test "receive hex string not hex" do
    receive_message "h\000o\000l\000a\000", 8, 'hola', :endianness_mo => :little, :accept_mo_hex_string => true
  end

  test "receive with hex substring" do
    receive_message "hola0061", 0, 'hola0061', :accept_mo_hex_string => true
  end

  test "receive lao message" do
    pdubin = '0000003d000000050000000000002a6f00000038353632303232313032383900000032343838000000000000000000000c306538313065383230653834'
    pdu = Smpp::Pdu::Base.create(pdubin.scan(/../).map{|x| x.to_i(16).chr}.join)

    @chan.configuration[:mt_encodings] = ['ascii']
    @chan.configuration[:endianness_mo] = :big
    @chan.configuration[:default_mo_encoding] = 'ascii'
    @chan.configuration[:mt_csms_method] = 'udh'
    @chan.configuration[:accept_mo_hex_string] = '1'
    @chan.save!
    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)

    @delegate.mo_received @transceiver, pdu
    msgs = AtMessage.all
    assert_equal 1, msgs.length
    msg = msgs[0]
    assert_equal 'sms://856202210289', msg.from
    assert_equal 'sms://2488', msg.to
    assert_equal "ກຂຄ", msg.body
    assert_equal @chan.id, msg.channel_id
  end

  test "receive unkonwn encoding" do
    receive_message "h\000o\000l\000a\000", 7, "h\000o\000l\000a\000"
  end

  test "receive concatenated sms with udh creates part" do
    receive_message "\005\000\003\123\003\001hola", 0, 'hola', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 1
  end

  test "receive concatenated sms with udh creates message" do
    receive_message "\005\000\003\123\003\001uno", 0, 'uno', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 1
    receive_message "\005\000\003\123\003\002dos", 0, 'dos', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 2
    receive_message "\005\000\003\123\003\003tres", 0, 'unodostres', :esm_class => 64
    assert_equal 0, SmppMessagePart.count
  end

  test "receive concatenated sms from two sources at the same time" do
    receive_message "\005\000\003\001\002\001one", 0, 'one', :from => '8881', :part => true, :esm_class => 64, :reference_number => 0001, :part_count => 2, :part_number => 1
    receive_message "\005\000\003\001\002\001two", 0, 'two', :from => '8882', :part => true, :esm_class => 64, :reference_number => 0001, :part_count => 2, :part_number => 1
    receive_message "\005\000\003\001\002\002three", 0, 'onethree', :from => '8881', :esm_class => 64
    AtMessage.delete_all
    receive_message "\005\000\003\001\002\002four", 0, 'twofour', :from => '8882', :esm_class => 64
  end

  test "obsolete message parts are discarded" do
    receive_message "\005\000\003\001\002\001one", 0, 'one', :from => '8881', :part => true, :esm_class => 64, :reference_number => 0001, :part_count => 2, :part_number => 1
    part = SmppMessagePart.first
    part.created_at = part.created_at - 2.hours
    part.save!
    receive_message "\005\000\003\001\002\001two", 0, 'two', :from => '8882', :part => true, :esm_class => 64, :reference_number => 0001, :part_count => 2, :part_number => 1
    assert_equal 1, SmppMessagePart.count
  end

  test "receive sms with udh" do
    receive_message "\005\001\003\123\003\001hola", 0, 'hola', :part => false, :esm_class => 64
  end

  test "receive concatenated sms with optional parameters" do
    receive_message "hola", 0, 'hola', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x01"}, :reference_number => 0x3d, :part_count => 3, :part_number => 1
  end

  test "reassemble concatenated sms with optional parameters" do
    receive_message "uno", 0, 'uno', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x01"}, :reference_number => 0x3d, :part_count => 3, :part_number => 1
    receive_message "dos", 0, 'dos', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x02"}, :reference_number => 0x3d, :part_count => 3, :part_number => 2
    receive_message "tres", 0, 'unodostres', :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x03"}
    assert_equal 0, SmppMessagePart.count
  end

  test "receive message from payload" do
    receive_message '', 0, 'hola mundo', :optional_parameters => { 0x0424 => "hola mundo"}
  end

  test "delivery report received DELIVRD" do
    assert_delivery_report '7b', 'confirmed', :msg_reference => '123', :stat => 'DELIVRD'
  end

  test "delivery report received DELIVRD with alphanumeric message id" do
    assert_delivery_report 's123', 'confirmed', :msg_reference => 's123', :stat => 'DELIVRD'
  end

  test "delivery report received DELIVRD using optional parameters receipted_message_id" do
    assert_delivery_report '7b', 'confirmed', :receipted_message_id => '7B', :stat => 'DELIVRD'
  end

  test "delivery report received DELIVRD using optional parameters message_state" do
    assert_delivery_report '7b', 'confirmed', :msg_reference => '123', :message_state => 2
  end

  test "delivery report received failed" do
    assert_delivery_report '7b', 'failed', :msg_reference => '123', :stat => 'REJECTED'
  end

  test "delivery report received failed using optional parameters message_state" do
    assert_delivery_report '7b', 'failed', :msg_reference => '123', :message_state => 3
  end

  test "delivery report received ignore duplicate" do
    save_channel_with_default_config

    msg = AoMessage.create! :account => @chan.account, :channel => @chan, :channel_relative_id => '123'
    pdu = Smpp::Pdu::DeliverSm.new '4444', '8888', 'hola', {:msg_reference => 123, :stat => 'REJECTED'}

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.delivery_report_received @transceiver, pdu

    count = Log.count
    @delegate.delivery_report_received @transceiver, pdu
    assert_equal count, Log.count
  end

  test "message accepted with delivery report digicel" do
    pdu_submit_sm_response_bin = '0000001880000004000000004babeef13133636335326100'.gsub(/\s/, '')
    pdu_deliver_sm_bin = '000000c50000000500000000000000d60001013530393337 3632 3932 3938 00000134 3633 3600 0400 0000 0000 0000 007a6964 3a30 3032 3037 3539 3835 3020 7375623a 3030 3120 646c 7672 643a 3030 31207375 626d 6974 2064 6174 653a 3130 30333236 3033 3234 2064 6f6e 6520 6461 74653a31 3030 3332 3630 3332 3420 7374 61743a44 454c 4956 5244 2065 7272 3a30 30302074 6578 743a 4d65 7373 6167 6520 73656e74 2073 7563 6365 7373 000e 0001 01000600 0101 001e 0008 3133 6363 3532 61000427 0001 02'.gsub(/\s/, '')
    assert_message_accepted_with_delivery_receipt pdu_submit_sm_response_bin, pdu_deliver_sm_bin
  end

  test "message accepted with delivery report comcel" do
    pdu_submit_sm_response_bin = '0000 0019 8000 0004 0000 0000 4bac 0d3a 3030 6239 3132 3538 00'.gsub(/\s/, '')
    pdu_deliver_sm_bin = '0000 00aa 0000 0005 0000 0000 0000 255f0001 0135 3039 3339 3032 3932 3132 00010134 3633 3600 0400 0000 0000 0000 007a6964 3a30 3031 3231 3238 3835 3620 7375623a 3030 3120 646c 7672 643a 3030 31207375 626d 6974 2064 6174 653a 3130 30333235 3230 3332 2064 6f6e 6520 6461 74653a31 3030 3332 3532 3033 3220 7374 61743a44 454c 4956 5244 2065 7272 3a30 30302074 6578 743a 4d65 7373 6167 6520 73656e74 2073 7563 6365 7373'.gsub(/\s/, '')
    assert_message_accepted_with_delivery_receipt pdu_submit_sm_response_bin, pdu_deliver_sm_bin
  end

  test "message accepted with delivery report smart" do
    pdu_submit_sm_response_bin = '0000 001e 8000 0004 0000 0000 4bab e8bf3334 3738 3736 3234 3431 3334 3800'.gsub(/\s/, '')
    pdu_deliver_sm_bin = '0000 005b 0000 0005 0000 0000 0000 00070001 0138 3535 3933 3231 3230 3031 00000132 3032 3000 0400 0000 0000 0008 0000001e 000e 3334 3738 3736 3234 3431 33343800 0427 0001 0215 0c00 0b31 3236 39353735 3931 3700 150d 0001 05'.gsub(/\s/, '')
    assert_message_accepted_with_delivery_receipt pdu_submit_sm_response_bin, pdu_deliver_sm_bin
  end

  test "message accepted" do
    save_channel_with_default_config

    msg = AoMessage.create! :account => @chan.account, :channel => @chan
    pdu = Smpp::Pdu::SubmitSmResponse.new 456, 0, '7B'

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.message_accepted @transceiver, msg.id, pdu

    msg = AoMessage.find_by_id msg.id
    assert_equal 'delivered', msg.state
    assert_equal '7b', msg.channel_relative_id
  end

  test "message rejected" do
    save_channel_with_default_config

    msg = AoMessage.create! :account => @chan.account, :channel => @chan
    pdu = Smpp::Pdu::SubmitSmResponse.new 456, 0, '7b'

    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.message_rejected @transceiver, msg.id, pdu

    msg = AoMessage.find_by_id msg.id
    assert_equal 'failed', msg.state
  end

end

