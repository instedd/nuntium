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

require 'iconv'

class SmppTransceiverDelegate

  EncodingCode = { "ascii" => 1, "latin1" => 3, "ucs-2be" => 8, "ucs-2le" => 8 }

  def initialize(transceiver, channel)
    @transceiver = transceiver
    @channel = channel
    @encodings = @channel.mt_encodings.map { |x| encoding_endianized(x, :mt) }
    @mt_max_length = @channel.mt_max_length.to_i
    @mt_csms_method = @channel.mt_csms_method
    @delivery_report_cache = Cache.new(nil, nil, 100, 86400)
    @default_mo_encoding = @channel.default_mo_encoding
  end

  def send_message(id, from, to, text, options = {})
    msg_text = nil
    msg_coding = nil

    # Select best encoding for the message
    @encodings.each do |encoding|
      iconv = Iconv.new(encoding, 'utf-8')
      msg_text = iconv.iconv(text) rescue next
      msg_coding = EncodingCode[encoding]
      break
    end

    if msg_text.nil?
      logger.warning "Could not find suitable encoding for AoMessage with id #{id}"
      return "Could not find suitable encoding"
    else
      msg_text.force_encoding 'ascii-8bit'
    end

    send_options = {}
    options.each do |key, value|
      send_options[:optional_parameters] ||= {}
      send_options[:optional_parameters][key] = Smpp::OptionalParameter.new(key, value)
    end
    send_options[:service_type] = @channel.service_type if @channel.service_type.present?

    if msg_text.length > @mt_max_length
      case @mt_csms_method
      when 'udh'
        send_csms_using_udh id, from, to, msg_coding, msg_text, send_options
      when 'optional_parameters'
        send_csms_using_optional_parameters id, from, to, msg_coding, msg_text, send_options
      when 'message_payload'
        send_csms_using_message_payload id, from, to, msg_coding, msg_text, send_options
      end
    else
      send_options[:data_coding] = msg_coding
      send_mt(id, from, to, msg_text, send_options)
    end

    return false
  end

  def send_csms_using_udh(id, from, to, msg_coding, msg_text, options)
    send_csms_using_block msg_text, @mt_max_length - 6 do |i, total, part|
      udh = sprintf("%c", 5)            # UDH is 5 bytes.
      udh << sprintf("%c%c", 0, 3)      # This is a concatenated message
      udh << sprintf("%c", id & 0xFF)          # The ID for the entire concatenated message
      udh << sprintf("%c", total)  # How many parts this message consists of
      udh << sprintf("%c", i + 1)         # This is part i+1

      options.merge!(
        :esm_class => 64,               # This message contains a UDH header.
        # UDH are bytes - not chars - so we use 8 bit encoding without interpretation
        :udh => udh.force_encoding("ASCII-8BIT"),
        :data_coding => msg_coding
      )

      send_mt(id, from, to, part, options)
    end
  end

  def send_csms_using_optional_parameters(id, from, to, msg_coding, msg_text, options)
    send_csms_using_block msg_text, @mt_max_length do |i, total, part|
      options[:data_coding] = msg_coding
      (options[:optional_parameters] ||= {}).merge!(
        0x020C => Smpp::OptionalParameter.new(0x020C, int_to_bytes_string(id, 2)),
        0x020E => Smpp::OptionalParameter.new(0x020E, int_to_bytes_string(total, 1)),
        0x020F => Smpp::OptionalParameter.new(0x020F, int_to_bytes_string(i + 1, 1))
      )

      send_mt(id, from, to, part, options)
    end
  end

  def send_csms_using_message_payload(id, from, to, msg_coding, msg_text, options)
    options[:data_coding] = msg_coding
    (options[:optional_parameters] ||= {}).merge!(
       0x0424 => Smpp::OptionalParameter.new(0x0424, msg_text)
    )

    send_mt(id, from, to, '', options)
  end

  def send_csms_using_block(msg_text, max_length)
    parts = []
    while msg_text.length > 0 do
      parts << msg_text.slice!(0...max_length)
    end

    0.upto(parts.size - 1) do |i|
      yield i, parts.size, parts[i]
    end
  end

  def mo_received(transceiver, pdu)
    logger.info "Message received from: #{pdu.source_addr}, to: #{pdu.destination_addr}, short_message: #{pdu.short_message.inspect}, optional_parameters: #{pdu.optional_parameters.inspect}"

    text = pdu.short_message

    # Use the message_payload optional parameter if present
    if text.length == 0 && pdu.optional_parameters && pdu.optional_parameters[0x0424]
      text = pdu.optional_parameters[0x0424].value
    end

    # Parse concatenated SMS from UDH
    if pdu.esm_class & 64 != 0
      udh = Udh.new(pdu.udh)
      if udh[0]
        ref = udh[0][:reference_number]
        total = udh[0][:part_count]
        partn = udh[0][:part_number]
        return part_received(pdu.source_addr, pdu.destination_addr, pdu.data_coding, text, ref, total, partn)
      end
    end

    # Parse concatenated SMS from optional parameters (sar_*)
    if pdu.optional_parameters && pdu.optional_parameters[0x020c] && pdu.optional_parameters[0x020e] && pdu.optional_parameters[0x020f]
      ref = bytes_to_int pdu.optional_parameters[0x020c].value
      total = bytes_to_int pdu.optional_parameters[0x020e].value
      partn = bytes_to_int pdu.optional_parameters[0x020f].value
      return part_received(pdu.source_addr, pdu.destination_addr, pdu.data_coding, text, ref, total, partn)
    end

    create_at_message pdu.source_addr, pdu.destination_addr, pdu.data_coding, text
  rescue Exception => e
    logger.error "Error in mo_received: #{e.class} #{e.to_s}"
    AccountLogger.exception_in_channel @channel, e
  end

  def delivery_report_received(transceiver, pdu)
    return if duplicated_receipt? pdu

    logger.info "Delegate: delivery_report_received: ref #{pdu.msg_reference} stat #{pdu.stat}"

    # Find message with channel_relative_id
    msg_reference = normalize(pdu.receipted_message_id || pdu.msg_reference.to_i.to_s(16))
    if msg_reference.length == 0
      msg_reference = (pdu.receipted_message_id || pdu.msg_reference)
    end

    msg = @channel.ao_messages.where(:channel_relative_id => msg_reference).first
    return logger.info "AoMessage with channel_relative_id #{msg_reference} not found" if msg.nil?

    # Reflect in message state
    if pdu.message_state
      msg.state = (pdu.message_state.to_s == '2' || pdu.message_state.to_s == '6') ? 'confirmed' : 'failed'
    elsif pdu.stat
      msg.state = (pdu.stat.to_s == 'DELIVRD' || pdu.stat.to_s == 'ACCEPTD') ? 'confirmed' : 'failed'
    end
    msg.save!

    @channel.account.logger.ao_message_status_receieved msg, (pdu.message_state || pdu.stat)
  rescue Exception => e
    logger.error "Error in delivery_report_received: #{e.class} #{e.to_s}"
    AccountLogger.exception_in_channel @channel, e
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    logger.info "Delegate: message_accepted: id #{mt_message_id} smsc ref id: #{pdu.message_id}"

    # Find message with mt_message_id
    msg = AoMessage.find_by_id mt_message_id
    return logger.info "AoMessage with id #{mt_message_id} not found (ref id: #{pdu.message_id})" if msg.nil?

    # smsc_message_id comes in hexadecimal
    reference_id = normalize(pdu.message_id)

    # Blank all messages with that reference id in case the reference id is already used
    AoMessage.update_all(['channel_relative_id = ?', nil], ['channel_id = ? AND channel_relative_id = ?', @channel.id, reference_id])

    # And set this message's channel relative id to later look it up
    # in the delivery_report_received method
    msg.channel_relative_id = reference_id
    msg.state = 'delivered'
    msg.tries += 1
    msg.save!

    @channel.account.logger.ao_message_status_receieved msg, 'ACK'
  rescue Exception => e
    logger.error "Error in message_accepted: #{e.class} #{e.to_s}"
    AccountLogger.exception_in_channel @channel, e
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    logger.info "Delegate: message_sent_with_error: id #{mt_message_id} pdu_command_status: #{pdu.command_status}"

    # Find message with mt_message_id
    msg = AoMessage.find_by_id mt_message_id
    return logger.info "AoMessage with id #{mt_message_id} not found (pdu_command_status: #{pdu.command_status})" if msg.nil?

    msg.state = 'failed'
    msg.tries += 1
    msg.save!

    @channel.account.logger.ao_message_status_warning msg, "Command Status '#{pdu.command_status}'"
  rescue Exception => e
    logger.error "Error in message_rejected: #{e.class} #{e.to_s}"
    AccountLogger.exception_in_channel @channel, e
  end

  def create_at_message(source, destination, data_coding, text)
    msg = AtMessage.new
    msg.from = source.with_protocol 'sms'
    msg.to = destination.with_protocol 'sms'
    if (@channel.accept_mo_hex_string.to_b) and text.is_hex?
      bytes = text.hex_to_bytes
      iconv = Iconv.new('utf-8', ucs2_endianized(:mo))
      msg.body = iconv.iconv bytes
    else
      if data_coding == 0 and @default_mo_encoding == 'gsm'
        msg.body = GsmDecoder.decode text
      else
        source_encoding = case data_coding
          when 0 then encoding_endianized(@default_mo_encoding, :mo)
          when 1 then 'ascii'
          when 3 then 'latin1'
          when 8 then ucs2_endianized(:mo)
        end

        if source_encoding
          iconv = Iconv.new('utf-8', source_encoding)
          msg.body = iconv.iconv text
        else
          msg.body = text
        end
      end
    end

    @channel.route_at msg
  end

  def part_received(source, destination, data_coding, text, ref, total, partn)
    # Discard unused message parts after one hour
    SmppMessagePart.where('created_at < ?', Time.current - 1.hour).delete_all

    parts = @channel.smpp_message_parts.where(:source => source, :reference_number => ref)
    all_parts = parts.all

    # If all other parts are here
    if parts.length == total-1
      # Add this new part, sort and get text
      parts.push SmppMessagePart.new(:part_number => partn, :text => text)
      parts.sort! { |x,y| x.part_number <=> y.part_number }
      text = parts.map(&:text).join

      # Create message from the resulting text
      create_at_message source, destination, data_coding, text

      # Delete stored information
      parts.delete_all
    else
      # Just save the part
      @channel.smpp_message_parts.create(
        :reference_number => ref,
        :part_count => total,
        :part_number => partn,
        :text => text,
        :source => source
      )
    end
  end

  private

  # Remove leading zeros and downcase
  def normalize(string_with_number)
    str = string_with_number.to_s
    idx = 0
    while idx < str.length and str[idx].chr == '0'
      idx += 1
    end
    str = str[idx .. -1] if idx != 0
    str.downcase
  end

  def duplicated_receipt?(pdu)
    cache_value = (pdu.receipted_message_id || pdu.msg_reference).to_s + (pdu.message_state || pdu.stat).to_s
    if @delivery_report_cache[cache_value.hash] == cache_value
      logger.info "Ignoring duplicate delivery report ref #{pdu.msg_reference} stat #{pdu.stat}"
      return true
    end
    @delivery_report_cache[cache_value.hash] = cache_value
    return false
  end

  def send_mt(id, from, to, text, options = {})
    logger.info "Sending id: '#{id}', from: '#{from}', to: '#{to}', text: '#{text.inspect}', options: '#{options.inspect}'"
    @transceiver.send_mt(id, from, to, text, options)
  end

  def encoding_endianized(encoding, direction)
    encoding == 'ucs-2' ? ucs2_endianized(direction) : encoding
  end

  def ucs2_endianized(direction)
    endianness = direction == :mo ? @channel.endianness_mo : @channel.endianness_mt
    endianness == 'little' ? 'ucs-2le' : 'ucs-2be'
  end

  def bytes_to_int(bytes)
    value = 0
    bytes.bytes.each do |x|
      value = (value << 8) + x
    end
    return value
  end

  def int_to_bytes_string(int, size)
    bytes = []
    size.times do
      bytes << (int & 0xff)
      int = (int >> 8)
    end
    bytes.reverse.pack('c*')
  end

  def logger
    Rails.logger
  end

end
class Smpp::OptionalParameter
  def ==(other)
    self.tag == other.tag && self.value == other.value
  end

  def to_s
    "[Tag: #{tag.inspect}, Value: #{value.inspect}]"
  end

  def inspect
    to_s
  end
end
