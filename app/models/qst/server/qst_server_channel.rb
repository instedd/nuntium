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

require 'digest/sha1'

class QstServerChannel < Channel
  has_many :qst_outgoing_messages, :foreign_key => 'channel_id'

  validates_presence_of :password

  configuration_accessor :password, :password_confirmation, :salt

  before_create :hash_password
  before_validation :rehash_password_if_changed, :on => :update

  validate :validate_password_confirmation
  validates_presence_of :ticket_code, :if => lambda { use_ticket.present? }

  attr_accessor :ticket_code, :ticket_message, :use_ticket
  before_save :ticket_record_password, :if => lambda { ticket_code.present? }
  after_save :ticket_mark_as_complete, :if => lambda { ticket_code.present? }

  before_save :infer_carrier

  def self.title
    "QST server (local gateway)"
  end

  def self.default_protocol
    'sms'
  end

  def handle(msg)
    outgoing = QstOutgoingMessage.new
    outgoing.channel_id = id
    outgoing.ao_message_id = msg.id
    outgoing.save
  end

  def authenticate(password)
    self.password == encode_password(decoded_salt, password)
  end

  def info
    self.class.send :include, ActionView::Helpers::DateHelper

    "Last activity: " + (last_activity_at ? "#{time_ago_in_words(last_activity_at)} ago" : 'never')
  end

  def has_connection?
    true
  end

  def matches_carrier_guids?(carrier_guids)
    return false unless self.carrier_guid

    self_carrier_guids = self.carrier_guid.split(",")
    self_carrier_guids.any? { |self_carrier_guid| carrier_guids.include?(self_carrier_guid) }
  end

  private

  def hash_password
    self.salt = SecureRandom.base64 8
    self.password = self.password_confirmation = encode_password(decoded_salt, password)
  end

  def rehash_password_if_changed
    if password.blank?
      old_configuration = configuration_was.dup
      self.password = self.password_confirmation = old_configuration[:password]
      self.salt = old_configuration[:salt]
    elsif configuration_was[:password] != password && password == password_confirmation
      hash_password
    end
  end

  def decoded_salt
    Base64.decode64 self.salt
  end

  def encode_password(salt, password)
    Base64.encode64(Digest::SHA1.digest(salt + Iconv.conv('ucs-2le', 'utf-8', password))).strip
  end

  def validate_password_confirmation
    errors.add :password, 'does not match confirmation' if password_confirmation && password != password_confirmation
  end

  def ticket_record_password
    ticket = Ticket.find_by_code_and_status ticket_code, 'pending'
    if ticket.nil?
      errors.add(:ticket_code, "Invalid code")
      return false
    end
    self.address = ticket.data[:address]
    @password_input = configuration[:password]
    return true
  end

  def ticket_mark_as_complete
    ticket = Ticket.complete ticket_code, { :channel => self.name, :account => self.account.name, :password => @password_input, :message => self.ticket_message }
  end

  def common_to_x_attributes
    attributes = super
    [:ticket_code, :ticket_message].each do |sym|
      value = send sym
      attributes[sym] = value if value.present?
    end
    attributes
  end

  def infer_carrier
    if address.present?
      countries, carriers = Carrier.infer_from_phone_number(address.mobile_number)
      unless carriers.empty?
        self.carrier_guid = carriers.map(&:guid).join(",")
      end
    else
      self.carrier_guid = nil
    end
    true
  end
end
