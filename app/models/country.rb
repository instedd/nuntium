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

class Country < ActiveRecord::Base
  has_many :carriers
  has_many :mobile_numbers

  before_destroy :clear_cache
  after_save :clear_cache

  @@countries = nil

  def self.all
    return @@countries if @@countries

    @@countries = super
    @@countries.sort!{|x, y| x.name <=> y.name}
    @@countries
  end

  def self.find_by_id(id)
    all.select{|c| c.id == id}.first
  end

  def self.find_by_iso2(iso2)
    all.select{|c| c.iso2.casecmp(iso2) == 0}.first
  end

  def self.find_by_iso3(iso3)
    all.select{|c| c.iso3.casecmp(iso3) == 0}.first
  end

  def self.find_by_iso2_or_iso3(iso)
    all.select{|c| c.iso2.casecmp(iso) == 0 || c.iso3.casecmp(iso) == 0}.first
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.country :name => name, :iso2 => iso2, :iso3 => iso3, :phone_prefix => phone_prefix
  end

  def as_json(options = {})
    {:name => name, :iso2 => iso2, :iso3 => iso3, :phone_prefix => phone_prefix}
  end

  def self.clear_cache
    @@countries = nil
  end

  private

  def clear_cache
    @@countries = nil
  end
end
