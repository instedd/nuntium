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
require 'zlib'
require 'base64'

module MessageFragmentation
  extend ActiveSupport::Concern

  MAX_MESSAGE_LENGTH = 140

  # Fragment format is:
  #
  #   &&TXXXNNN|msg|
  #   123456...7...8
  #
  # where:
  # - && is the header, just two ampersands, that indicates this is a fragmented message
  # - XXX is the message id: every fragement of each unique message has the same ID
  # - T is the kind of messge: 'A' is a fragment, 'B' is the last fragment, 'C' is "missing packets" and 'D' is ACK.
  # - N is the fragment number
  # - | is a pipe to indicate the end of the fragment number
  # - msg is the base64 encoded message
  # - | ends the message
  #
  # That is, 8 chars are always lost and extra chars are lost because of the fragment number.

  def needs_fragmentation?
    body && body.length > MAX_MESSAGE_LENGTH
  end

  def build_fragments
    compressed = Zlib::Deflate.deflate(body)
    base64 = Base64.strict_encode64(compressed).strip

    fragment_id = fragment_id()
    index = 0
    num = 0

    fragments = []

    while index < base64.length
      num_s = num.to_s
      count = MAX_MESSAGE_LENGTH - 8 - num_s.length
      piece = base64[index, count]
      index += count
      num += 1

      fragment = AoMessage.new account_id: account_id, application_id: application_id, from: from, to: to

      kind = index >= base64.length ? 'B' : 'A'
      fragment.body = "&&#{kind}#{fragment_id}#{num_s}|#{piece}|"
      fragment.parent_id = id
      fragment.failover_channels = failover_channels
      fragment.custom_attributes = custom_attributes.dup
      fragment.custom_attributes.delete "fragment"
      fragment.token = token

      fragments << fragment
    end

    fragments
  end

  def fragment_id
    self.class.fragment_id(id)
  end

  def handle_fragmentation_command
    if body
      if body.start_with?('&&C')
        ThreadLocalLogger.nest do
          fragment_id = body[3 ... 6]
          nums = body[6 .. -1].split(',').map { |p| p.strip.to_i }
          ao_messages_ids = AoMessageFragment.where(fragment_id: fragment_id, number: nums).order('id desc').pluck(:ao_message_id)
          aos = AoMessage.where(id: ao_messages_ids)

          # Make sure to re-route only the last AO messages that share the same parent_id
          parent_id = nil
          aos.each do |ao|
            if ao.parent_id != parent_id
              if parent_id
                break
              else
                parent_id = ao.parent_id
              end
            end
            application.reroute_ao(ao)
          end
        end
        true
      elsif body.start_with?('&&D')
        ThreadLocalLogger.nest do
          fragment_id = body[3 ... 6]
          fragment = AoMessageFragment.where(fragment_id: fragment_id).last
          ao_fragment = fragment.ao_message
          ao = AoMessage.find(ao_fragment.parent_id)
          ao.state = "confirmed"
          ao.save!
        end
      end
    end

    false
  end

  module ClassMethods
    def fragment_id(id)
      first = id / (62 * 62)
      id -= first * 62 * 62
      second = id / 62
      id -= second * 62
      third = id

      nums = [first, second, third]
      nums.map! do |num|
        if num < 10
          num.to_s
        elsif num < 36
          ('a'.ord + num - 10).chr
        else
          ('A'.ord + num - 36).chr
        end
      end
      nums.join
    end
  end
end
