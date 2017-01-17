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

class SmppServerChannel < BaseSmppChannel
  def self.title
    "SMPP Server"
  end

  def system_id
    if self.id
      "nuntium_#{id}"
    end
  end

  def check_password(password)
    self.password == password
  end

  def self.abstract?
    false
  end

  def self.find_by_system_id(id)
    if id =~ /^nuntium_(\d+)$/
      self.where(id: $1.to_i).where(kind: "smpp_server").first
    end
  end
end
