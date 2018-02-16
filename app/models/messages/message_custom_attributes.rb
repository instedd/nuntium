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

module MessageCustomAttributes
  extend ActiveSupport::Concern

  included do
    custom_attributes_accessor :country
    custom_attributes_accessor :carrier
    custom_attributes_accessor :strategy
    custom_attributes_accessor :suggested_channel
    custom_attributes_accessor :cost
    custom_attributes_accessor :fragment
  end

  # A Hash where each value can be a string or an Array of strings
  def custom_attributes
    self[:custom_attributes] ||= {}
  end

  # Optimizations can be:
  #  - :mobile_number => associated to the message, so that it does not need to
  #                      be read when completing missing fields
  def infer_custom_attributes(optimizations = {})
    address = self.kind_of?(AoMessage) ? to : from
    return unless address.try(:protocol) == 'sms'

    number = address.mobile_number

    # Infer country and carrier from phone number
    countries, carriers = Carrier.infer_from_phone_number(number, self.country, self.carrier)

    unless countries.empty?
      if countries.length == 1
        ThreadLocalLogger << "Country #{countries[0].name} (#{countries[0].iso2}) was inferred from prefix"
        self.country = countries[0].iso2
      else
        self.country = countries.map do |c|
          ThreadLocalLogger << "Country #{c.name} (#{c.iso2}) was inferred from prefix"
          c.iso2
        end
      end
    end

    unless carriers.empty?
      carriers.each do |carrier|
        ThreadLocalLogger << "Carrier #{carrier.name} was inferred from prefix"
      end

      self.carrier = carriers.length == 1 ? carriers[0].guid : carriers.map(&:guid)
    end

    # Infer country and carrier from stored MobileNumber, if any
    mob = optimizations[:mobile_number] || (MobileNumber.find_by_number number)
    mob.complete_missing_fields self if mob
  end

  module ClassMethods
    def custom_attributes_accessor(name, default = nil)
      define_method name  do
        custom_attributes[name.to_s] || default
      end
      define_method "#{name}=" do |value|
        custom_attributes[name.to_s] = value
      end
    end
  end
end
