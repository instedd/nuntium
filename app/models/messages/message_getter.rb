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

module MessageGetter
  extend ActiveSupport::Concern

  module ClassMethods
    def get_message(msg_or_id)
      if msg_or_id.kind_of? ActiveRecord::Base
        msg_or_id
      elsif msg_or_id.kind_of? Numeric
        find_by_id(msg_or_id)
      elsif msg_or_id.kind_of? String
        find_by_guid(msg_or_id)
      else
        msg_or_id
      end
    end
  end
end
