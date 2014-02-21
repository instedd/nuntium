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

class IpopChannel < Channel
  include GenericChannel

  configuration_accessor :mt_post_url, :mt_post_user, :mt_post_password, :bid, :cid
  validates_presence_of :address, :mt_post_url, :bid, :cid
  handle_password_change :mt_post_password

  def self.title
    "I-POP"
  end

  def self.default_protocol
    'sms'
  end

  def check_valid
    errors.add(:address, "can't be blank") if address.blank?
    check_config_not_blank :mt_post_url, :bid, :cid
  end

  def info
    address
  end

  StatusCodes = {
    3 => 'Failure',
    4 => 'Operator SMSC',
    5 => 'Successful billing or Mobile Acknowledgement',
    6 => 'Unsuccessful billing or Failed Mobile Acknowledgement'
  }

  DetailedStatusCodes = {
    10 => 'Invalid Number: Invalid subscriber - recycled msisdn',
    11 => 'Temporary Block - Operator temporary suspend',
    12 => 'Permanent Block: Blocked by the operator - pre/post-paid preference ban',
    13 => 'Insufficient Credit: Insufficient prepaid balance',
    14 => 'Retry Exhausted: other errors - gateway timeout',
    15 => 'Unkown 3rd Party Error',
    16 => 'MSISDN Not Registered at Op - MSISDN Blackout Period',
    18 => 'Reserved for future use'
  }
end
