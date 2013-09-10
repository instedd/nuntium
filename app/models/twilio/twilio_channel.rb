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

class TwilioChannel < Channel
  include GenericChannel

  configuration_accessor :account_sid, :auth_token, :from, :incoming_password
  validates_presence_of :account_sid, :auth_token, :from, :incoming_password

  before_validation :configure_phone_number
  def configure_phone_number
    client = Twilio::REST::Client.new account_sid, auth_token
    incoming_phones = client.account.incoming_phone_numbers.list

    pattern = /[\+\-\s\(\)]/
    from_lookup = from.gsub(pattern, '')
    target_phone = incoming_phones.find do |phone|
      phone.phone_number.gsub(pattern, '') == from_lookup
    end

    unless target_phone
      self.errors.add(:from, "was not found in your twilio account phone numbers")
      return false
    end

    self.incoming_password = Devise.friendly_token

    protocol = Settings.protocol
    host_name = Settings.host_name

    url = "#{protocol}://"
    url << name
    url << ":"
    url << self.incoming_password
    url << "@"
    url << host_name
    url << "/"
    url << account.name
    url << "/twilio/incoming"

    target_phone.update sms_url: url

    true
  rescue Twilio::REST::RequestError => ex
    case ex.message
    when /SmsUrl is not valid/
      self.errors.add(:account_sid, "the host #{host_name} is not valid for Twilio sms url")
    when /Authenticate/
      self.errors.add(:account_sid, "in combination with account token is invalid")
    else
      self.errors.add(:account_sid, ex.message)
    end
    false
  end

  def self.default_protocol
    'sms'
  end

  def info
    account_sid
  end
end
