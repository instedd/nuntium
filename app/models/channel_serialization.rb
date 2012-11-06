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

module ChannelSerialization
  extend ActiveSupport::Concern

  module InstanceMethods
    def as_json(options = {})
      options ||= {}

      attributes = common_to_x_attributes
      attributes[:configuration] = []
      configuration.each do |name, value|
        next if value.blank?
        is_password = name.to_s.include?('password') || name.to_s == 'salt'
        next if is_password && (options[:include_passwords].nil? || options[:include_passwords] === false)
        attributes[:configuration] << {:name => name, :value => value}
      end
      restrictions.each do |name, values|
        attributes[:restrictions] ||= []
        attributes[:restrictions] << {:name => name, :value => values}
      end unless restrictions.empty?
      attributes[:ao_rules] = ao_rules unless ao_rules.nil?
      attributes[:at_rules] = at_rules unless at_rules.nil?

      attributes
    end

    def to_xml(options = {})
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]

      attributes = common_to_x_attributes

      xml.channel attributes do
        xml.configuration do
          configuration.each do |name, value|
            next if value.blank?
            is_password = name.to_s.include?('password') || name.to_s == 'salt'
            next if is_password and (options[:include_passwords].nil? or options[:include_passwords] === false)
            xml.property :name => name, :value => value
          end
        end
        xml.restrictions do
          restrictions.each_multivalue do |name, values|
            values.each do |value|
              xml.property :name => name, :value => value
            end
          end
        end unless restrictions.empty?
        xml.ao_rules do
          RulesEngine.to_xml xml, ao_rules
        end unless ao_rules.nil?
        xml.at_rules do
          RulesEngine.to_xml xml, at_rules
        end unless at_rules.nil?
      end
    end

    def common_to_x_attributes
      attributes = {}
      [:name, :kind, :protocol, :enabled, :priority, :address, :ao_cost, :at_cost, :last_activity_at].each do |sym|
        value = send sym
        attributes[sym] = value if value.present?
      end
      attributes[:direction] = direction_text unless direction_text == 'unknown'
      attributes[:application] = application.name if application_id
      attributes[:queued_ao_messages_count] = queued_ao_messages_count
      attributes[:connected] = connected? if has_connection?
      attributes
    end
  end

  module ClassMethods
    def from_json(hash_or_string)
      if hash_or_string.empty?
        tree = {}
      else
        tree = hash_or_string.kind_of?(Hash) ? hash_or_string.with_indifferent_access : JSON.parse(hash_or_string).with_indifferent_access
      end
      Channel.from_hash tree, :json
    end

    def from_xml(hash_or_string)
      if hash_or_string.empty?
        tree = {:channel => {}}
      else
        tree = hash_or_string.kind_of?(Hash) ? hash_or_string : Hash.from_xml(hash_or_string)
      end
      tree = tree.with_indifferent_access
      Channel.from_hash tree[:channel], :xml
    end

    def from_hash(hash, format)
      hash = hash.with_indifferent_access

      chan = (hash[:kind].try(:to_channel) || Channel).new
      [:name, :kind, :protocol, :priority, :address, :ao_cost, :at_cost].each do |sym|
        chan.send "#{sym}=", hash[sym]
      end
      chan.enabled = hash[:enabled].to_b
      chan.direction = hash[:direction] if hash[:direction]
      chan.ticket_code = hash[:ticket_code] if hash[:ticket_code]
      chan.ticket_message = hash[:ticket_message] if hash[:ticket_message]

      hash_config = hash[:configuration].presence || {}
      hash_config = hash_config[:property] || [] if format == :xml && hash_config[:property].present?
      hash_config = [hash_config] unless hash_config.blank? || hash_config.kind_of?(Array) || hash_config.kind_of?(String)

      hash_config.each do |property|
        chan.configuration.store_multivalue property[:name].to_sym, property[:value]
      end unless hash_config.kind_of? String

      hash_restrict = hash[:restrictions].presence || {}
      hash_restrict = hash_restrict[:property] || [] if format == :xml && hash_restrict[:property]
      hash_restrict = [hash_restrict] unless hash_restrict.blank? || hash_restrict.kind_of?(Array) || hash_restrict.kind_of?(String)

      # force the empty hash at least, if the restrictions were specified
      # this is needed for proper merging when updating through api
      chan.restrictions if hash.has_key? :restrictions

      hash_restrict.each do |property|
        chan.restrictions.store_multivalue property[:name], property[:value]
      end unless hash_restrict.kind_of? String

      chan.ao_rules = RulesEngine.from_hash hash[:ao_rules], format if hash.has_key?(:ao_rules)
      chan.at_rules = RulesEngine.from_hash hash[:at_rules], format if hash.has_key?(:at_rules)

      chan
    end
  end
end
