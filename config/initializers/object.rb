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

class Object
  def to_b
    if self.class <= String
      self.downcase == 'true' || self == '1'
    elsif self.class == NilClass
      false
    else
      self
    end
  end

  def ensure_array
    if self.kind_of? Array
      self
    elsif self.nil?
      []
    else
      [self]
    end
  end

  def subclasses_of(klass)
    subclasses = klass.descendants
    subclasses.each do |subclass|
      subclasses.push *subclasses_of(subclass)
    end
  end
end
