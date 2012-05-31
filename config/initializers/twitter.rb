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

# This is a monkey patch for the friendships/exists call.
# Twitter returns true or false and JSON.parse chokes on it.
# So we handle those values separately.
module Twitter
  def self.parse(response)
    return '' if response.body == ''
    return true if response.body == 'true'
    return false if response.body == 'false'
    JSON.parse(response.body)
  end
end
