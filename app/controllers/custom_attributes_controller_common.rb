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

module CustomAttributesControllerCommon
  def get_custom_attributes
    custom_attribute_names = params[:custom_attribute_name] || []
    custom_attribute_values = params[:custom_attribute_value] || []
    custom_attribute_options =  params[:custom_attribute_optional] || []

    custom_attributes = ActiveSupport::OrderedHash.new

    return custom_attributes if not custom_attribute_names

    0.upto(custom_attribute_names.length).each do |i|
      name = custom_attribute_names[i]
      value = custom_attribute_values[i]
      next unless name and value
      custom_attributes.store_multivalue name, value
    end

    i = 0
    j = 0
    while i < custom_attribute_options.length
      name = custom_attribute_names[j]
      next unless name

      if custom_attribute_options[i + 1].to_b
        custom_attributes.store_multivalue custom_attribute_names[j], ''
        i += 1
      end
      i += 1
      j += 1
    end

    custom_attributes
  end
end
