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

require 'guid'

module MessageCommon
  extend ActiveSupport::Concern

  Fields = ['from', 'to', 'subject', 'body', 'guid']

  included do
    before_save :generate_guid
    scope :with_state, lambda { |*state| where(:state => state) }
  end

  module InstanceMethods
    def generate_guid
      self.guid ||= Guid.new.to_s
    end

    # Returns the subject and body of this message concatenated
    # with a dash, or either of them if the other is empty.
    def subject_and_body
      if subject.blank?
        body.blank? ? '' : body
      else
        body.blank? ? subject : "#{subject} - #{body}"
      end
    end

    def from=(value)
      value = value.mobile_number.with_protocol('sms') if value && value.protocol == 'sms'
      super value
    end

    def to=(value)
      value = value.mobile_number.with_protocol('sms') if value && value.protocol == 'sms'
      super value
    end

    def timestamp=(value)
      value = Time.now.utc if value && value > Time.now
      write_attribute 'timestamp', value
    end

    # Rule Engine related methods

    # Builds Context for AT Rules execution
    def rules_context
      {
        "from" => self.from,
        "to" => self.to,
        "subject" => self.subject,
        "body" => self.body,
        "subject_and_body" => self.subject_and_body
      }.merge self.custom_attributes
    end

    # merge attributes to current instance.
    # wellknown attributes are persisted in properties. Others as extensions
    def merge(attributes)
      attributes ||= {}
      original = {}

      Fields.each do |sym|
        if attributes.has_key? sym
          old = send sym
          send "#{sym}=", attributes[sym]
          original[sym] = old unless original[sym]
          ThreadLocalLogger << "'#{sym}' changed from '#{old}' to '#{attributes[sym]}'"
        end
      end

      other_attributes = attributes.reject { |k,v| Fields.include?(k) }
      other_attributes.each do |key, value|
        if key == 'cancel'
          self.state = 'canceled'
        else
          old = custom_attributes[key]
          custom_attributes[key] = value
          original[key] = old unless original[key]
          ThreadLocalLogger << "'#{key}' changed from '#{old}' to '#{value}'"
        end
      end

      original.present? ? original : nil
    end
  end
end
