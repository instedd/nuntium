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

require 'strscan'

# Represents a search. It's a hash of key value pairs plus a search string.
#
# Examples:
#   Search.new('hello') => search = 'hello', {}
#   Search.new('key:value') => search = nil, {:key => 'value'}
#   Search.new('key:"many words"') => search = nil, {:key => 'many words'}
#   Search.new('something key:"many words"') => search = 'something', {:key => 'many words'}
#   Search.new('sms://foo') => search = 'sms://foo', {}
#   Search.new('from:sms://foo') => search = nil, {:from => 'sms://foo'}
#
class Search < Hash
  attr_reader :search

  def initialize(str)
    return if str.nil?

    s = StringScanner.new(str)

    until s.eos?
      # Skip whitespace
      s.scan(/\s+/)

      # Get next work
      key = s.scan(/\w+/)

      # Check if there's a colon so we have key:...
      # (but not key://)
      colon = s.scan(/:/)
      if colon
        # Check key://value
        value = s.scan(/\/\/(\S)+/)
        if value
          add_to_search("#{key}:#{value}")
          next
        end

        # Check key:"value"
        value = s.scan(/".+?"/)
        value = value ? value[1...-1] : s.scan(/(\S)+/)
        self[key.to_sym] = value
        next
      end

      key = s.scan(/"(\w|\s)+"/) if key.nil?
      key = s.scan(/\W+/) if key.nil?

      # Just a word to add to the search
      add_to_search key
    end
  end

  def add_to_search(value)
    @search = @search ? "#{@search} #{value}" : value
  end

  def self.get_op_and_val(val)
    op = '='
    if val.length > 1 && (val[0..1] == '<=' || val[0..1] == '>=')
      op = val[0..1]
      val = val[2..-1]
    elsif val.length > 0 && (val[0].chr == '<' || val[0].chr == '>')
      op = val[0].chr
      val = val[1..-1]
    end
    [op, val]
  end
end
