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

class MobileNumber < ActiveRecord::Base
  belongs_to :country
  belongs_to :carrier

  def country
    country_id ? (Country.find_by_id country_id) : nil
  end

  def carrier
    carrier_id ? (Carrier.find_by_id carrier_id) : nil
  end

  def self.update(number, country, carrier, options = {})
    simulate = options[:simulate]

    if country and not country.kind_of? Array
      country = Country.find_by_iso2_or_iso3 country if country
    else
      country = nil
    end
    if carrier and not carrier.kind_of? Array
      carrier = Carrier.find_by_guid carrier if carrier
    else
      carrier = nil
    end
    if country or carrier
      mob = MobileNumber.find_by_number number
      mob = MobileNumber.new(:number => number) if mob.nil?
      if country
        mob.country_id = country.id
        ThreadLocalLogger << "The number #{number} is now associated with country #{country.name} (#{country.iso2})"
      end
      if carrier
        mob.carrier_id = carrier.id
        ThreadLocalLogger << "The number #{number} is now associated with carrier #{carrier.name} (#{carrier.guid})"
      end
      mob.save! unless simulate
      return mob
    end

    return nil
  end

  def complete_missing_fields(msg)
    # complete country
    if not msg.country and country
      ThreadLocalLogger << "Country #{country.name} (#{country.iso2}) was inferred from mobile numbers table"
      msg.country = country.iso2
    end
    # complete carrier
    if not msg.carrier and carrier
      ThreadLocalLogger << "Carrier #{carrier.name} (#{carrier.guid}) was inferred from mobile numbers table"
      msg.carrier = carrier.guid
    end
  end
end
