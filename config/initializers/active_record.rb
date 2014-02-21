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

class ActiveRecord::Base
  def self.configuration_accessor(*names)
    options = names.extract_options!
    default = options[:default]

    names.each do |name|
      define_method(name) do
        configuration[name] || default
      end
      define_method("#{name}=") do |value|
        configuration_will_change!
        configuration[name] = value
      end
    end
  end

  def self.handle_password_change(name = :password)
    class_eval %Q(
      before_validation :_restore_#{name}, :on => :update

      def _restore_#{name}
        self.#{name} = self.configuration_was[:#{name}] if self.#{name}.blank?
      end
    )
  end
end
