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

class Carrier < ApplicationRecord
  belongs_to :country
  has_many :mobile_numbers

  before_destroy :clear_cache
  after_save :clear_cache

  @@carriers = nil

  def self.all_carriers
    return @@carriers if @@carriers

    @@carriers = self.all.to_a
    @@carriers.sort!{|x, y| x.name <=> y.name}
    @@carriers
  end

  def self.all_with_countries
    countries = Country.all_countries.inject({}) { |memo, obj| memo[obj.id] = obj; memo }

    carriers = all
    carriers.each {|c| c.country = countries[c.country_id]}
    carriers
  end

  def self.find_by_id(id)
    all.select{|c| c.id == id}.first
  end

  def self.find_by_country_id(country_id)
    all.select {|x| x.country_id == country_id}
  end

  def self.find_by_guid(guid)
    all.select {|x| x.guid == guid}.first
  end

  def self.find_by_name(name)
    all.select {|x| x.name == name}.first
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.carrier :name => name, :guid => guid, :country_iso2 => country.iso2
  end

  def as_json(options = {})
    {:name => name, :guid => guid, :country_iso2 => country.iso2}
  end

  def self.clear_cache
    @@carriers = nil
  end

  # Returns [countries, carriers]
  def self.infer_from_phone_number(number, country_iso = nil, carrier_iso = nil)
    countries = []
    carriers = []

    # Infer country from phone number
    unless country_iso
      countries = Country.all.select{|x| number.start_with? x.phone_prefix}
      if countries.length > 0
        # Slipt countries with and without area codes
        with_area_codes, without_area_codes = countries.partition{|x| x.area_codes.present?}
        # From those with area codes, select only the ones for which the number start with them
        with_area_codes = with_area_codes.select{|x| x.area_codes.split(',').any?{|y| number.start_with?(x.phone_prefix + y.strip)}}
        # If we find matches with area codes, use them. Otherwise, use those without area codes
        countries = with_area_codes.present? ? with_area_codes : without_area_codes

        if countries.length == 1
          country_iso = countries[0].iso2
        else
          country_iso = countries.map(&:iso2)
        end
      end
    end

    # Infer carrier from phone number (if country is present)
    if country_iso && !carrier_iso
      carrier_countries = country_iso
      carrier_countries = [carrier_countries] unless carrier_countries.kind_of? Array
      carrier_countries = carrier_countries.map{|x| Country.find_by_iso2_or_iso3 x}

      carrier_countries.each do |c|
        next unless c
        cs = Carrier.find_by_country_id c.id
        cs.each do |carrier|
          next unless carrier.prefixes.present?
          prefixes = carrier.prefixes.split ','
          if prefixes.any?{|p| number.start_with?(c.phone_prefix + p.strip)}
            carriers << carrier
          end
        end
      end
    end

    [countries, carriers]
  end

  private

  def clear_cache
    @@carriers = nil
  end
end
