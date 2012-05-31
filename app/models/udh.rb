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

class Udh

  attr_reader :length
  
  def initialize(str)
    @attributes = {}
    if str.nil? or str.empty?
      @length = 0
      return
    end
    
    @length = str[0]
    
    i = 1
    while i <= @length
      byte = str[i]
      if byte == 0
        i += 2
        self[0] = {}
        self[0][:reference_number] = str[i]
        i += 1
        self[0][:part_count] = str[i]
        i += 1
        self[0][:part_number] = str[i]
        i += 1
      else
        i += 1
        byte = str[i]
        i += byte + 1
      end
    end
  end
  
  def [](key)
    @attributes[key]
  end
  
  def skip(text)
    text[1 + @length .. -1]
  end
  
  private
  
  def []=(key, value)
    @attributes[key] = value
  end

end
