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

ActiveSupport::OrderedHash

# See https://rails.lighthouseapp.com/projects/8994/tickets/2123-orderedhash-to_hash-and-sort
module ActiveSupport
  class OrderedHash
    def to_yaml_type
      "!tag:yaml.org,2002:omap"
    end
    
    def to_yaml(opts = {})
      YAML.quick_emit(self, opts) do |out|
        out.seq(taguri, to_yaml_style) do |seq|
          each do |k, v|
            seq.add(k => v)
          end
        end
      end
    end
  end
  
  YAML.add_builtin_type("omap") do |type, val|
    ActiveSupport::OrderedHash[val.map(&:to_a).map(&:first)]
  end
end
