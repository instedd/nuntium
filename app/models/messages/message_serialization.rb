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

module MessageSerialization
  extend ActiveSupport::Concern

  def write_xml(xml)
    options = {:id => self.guid, :from => self.from, :to => self.to}
    options[:when] = self.timestamp.xmlschema if self.timestamp
    xml.message(options) do
      xml.text self.subject_and_body
      custom_attributes.each_multivalue do |name, values|
        values.each { |value| xml.property :name => name, :value => value }
      end
      xml.property :name => 'token', :value => self.token if self.token
    end
  end

  def to_qst
    hash = {'id' => guid, 'from' => from, 'to' => to, 'text' => subject_and_body, 'when' => timestamp}
    hash['properties'] = custom_attributes if custom_attributes.present?
    hash
  end

  def as_json(options = {})
    hash = {}
    MessageCommon::Fields.each do |field|
      value = send field
      hash[field] = value if value
    end
    hash['channel'] = channel.try(:name)
    hash['channel_kind'] = channel.try(:kind)
    hash['state'] = state
    hash.merge!(custom_attributes)
    hash
  end

  module ClassMethods
    def write_xml(msgs)
      xml = Builder::XmlMarkup.new(:indent => 1)
      xml.instruct!
      xml.messages do
        msgs.each do |msg|
          msg.write_xml xml
        end
      end
      xml.target!
    end

    def to_qst(msgs)
      msgs.map &:to_qst
    end

    def from_qst(msgs)
      msgs.map do |x|
        m = self.new :guid => x['id'], :from => x['from'], :to => x['to'], :body => x['text'], :timestamp => x['when']
        m.custom_attributes = x['properties'] if x['properties'].present?
        m
      end
    end

    # Given an xml document string extracts all messages from it and yields them
    def parse_xml(txt_or_hash)
      tree = txt_or_hash.kind_of?(Hash) ? txt_or_hash : Hash.from_xml(txt_or_hash).with_indifferent_access

      messages = ((tree || {})[:messages] || {})[:message]
      messages = [messages] if messages.class <= Hash

      (messages || []).each do |elem|
        next if elem.kind_of? String

        msg = self.new
        msg.from = elem[:from]
        msg.to = elem[:to]
        msg.body = elem[:text]
        msg.guid = elem[:id] if elem[:id].present?
        msg.timestamp = Time.parse(elem[:when]) if elem[:when] rescue nil

        properties = elem[:property]
        if properties.present?
          properties = [properties] if properties.class <= Hash
          properties.each do |prop|
            if prop[:name] == 'token'
              msg.token = prop[:value]
            else
              msg.custom_attributes.store_multivalue prop[:name], prop[:value]
            end
          end
        end

        yield msg
      end
    end

    def from_json(data)
      data = JSON.parse(data) if data.is_a? String
      data = [data] unless data.is_a? Array
      data.each { |hash| yield from_hash(hash) }
    end

    def from_hash(hash)
      hash = hash.with_indifferent_access

      msg = self.new
      hash.each do |key, value|
        if [:from, :to, :subject, :body, :guid, :token].include? key.to_sym
          # Normal attribute
          msg.send "#{key}=", value
        elsif [:controller, :action, :application_name, :account_name].include? key.to_sym
          # Nothing, ignore these because they come from the request
        else
          # Custom attribute
          msg.custom_attributes[key] = value
        end
      end
      msg
    end
  end
end
