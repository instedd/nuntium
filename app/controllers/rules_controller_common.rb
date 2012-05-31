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

module RulesControllerCommon

  def get_rules(param_key)
    def safe_values(hash, key)
      h = hash[key]
      h.nil? ? [] : h.values
    end

    rules_hash = params[param_key] || {}
    rules_hash = flatten rules_hash
    rules_hash.each do |rule|
      ["matchings", "actions"].each do |key|
        rule[key] = flatten rule[key] if rule[key].present?
      end
    end

    rules_hash
  end

  private

  def flatten(hash)
    res = []
    hash.keys.map(&:to_i).sort.each do |key|
      res << hash[key.to_s]
    end
    res
  end

end
