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

class Hash

  # If the old value of the key does not exist:
  #  - this is equivalent to hash[key] = value
  # If the old value exists:
  #  - If it's an array, the value is appended to it
  #  - Else, the new value will be an array containing the previous and new values.
  def store_multivalue(key, value)
    old = self[key]
    if old
      if old.kind_of? Array
        old << value
      else
        self[key] = [old, value]
      end
    else
      self[key] = value
    end
  end

  # Same as each, but every yielded value will be an array
  def each_multivalue
    each do |key, values|
      values = [values] unless values.kind_of? Array
      yield key, values
    end
  end

  def to_human
    map {|k,v| "#{k}: #{v.is_a?(Array) ? "(#{v.join(', ')})" : v}"}.join(', ')
  end

end
