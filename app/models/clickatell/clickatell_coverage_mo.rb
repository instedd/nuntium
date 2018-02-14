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

class ClickatellCoverageMO < ApplicationRecord
  belongs_to :country
  belongs_to :carrier

  before_destroy :clear_cache
  after_save :clear_cache

  def country
    country_id ? (Country.find_by_id country_id) : nil
  end

  def carrier
    carrier_id ? (Carrier.find_by_id carrier_id) : nil
  end

  def self.find_all_by_network(network)
    mos = Rails.cache.read 'clickatell_coverage_mos'
    if not mos
      mos = ClickatellCoverageMO.all
      to_cache = Hash.new
      mos.each do |mo|
        to_cache[mo.network] = [] unless to_cache.has_key? mo.network
        to_cache[mo.network] << mo
      end
      mos = to_cache
      Rails.cache.write 'clickatell_coverage_mos', mos
    end
    mos[network] || []
  end

  private

  def clear_cache
    Rails.cache.delete 'clickatell_coverage_mos'
    true
  end

end
