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

class ShujaaChannel < Channel
  include GenericChannel

  DEFAULT_URL = "http://sms.shujaa.mobi"

  AIRTEL = "10a23e2c-6449-983c-55ac-ba9643d4c423"
  ORANGE = "0614982d-5492-41a6-b7f8-dc49b8ee87aa"
  SAFARICOM = "4c14ffca-0a77-b014-c2fa-39d06dcae2fc"
  YU = "1e772e3a-c675-44ca-b954-70ab2fa1f1fd"

  configuration_accessor :shujaa_url, :username, :password, :shujaa_account, :callback_guid
  validates_presence_of :address, :username, :password, :shujaa_account, :callback_guid
  handle_password_change

  before_create :autogenerate_callback_guid
  def autogenerate_callback_guid
    callback_guid
    true
  end

  def self.default_protocol
    'sms'
  end

  def info
    "#{username} (#{account})"
  end

  def callback_guid
    configuration[:callback_guid] ||= Guid.new.to_s
  end

  def shujaa_url
    configuration[:shujaa_url] || DEFAULT_URL
  end

  def more_info(ao_msg)
    return {} if ao_msg.channel_relative_id.nil?

    params = {}
    params[:username] = username
    params[:password] = password
    params[:account] = account
    params[:messageId] = ao_msg.channel_relative_id

    response = RestClient.get "#{shujaa_url}/querystatus?#{params.to_query}"
    if response.body =~ /(.+)\:(.+)/
      msg_status_code = $2
      entry = SHUJAA_ERRORS[msg_status_code.to_i]
      return {
        "Shujaa Status Code" => msg_status_code,
        "Shujaa Status Description" => entry[:description],
      }
    end

    {}
  end

=begin
  Shujaa errors are mapped as fatal, temporary, message, or ok.
  These categories are used to trap exceptions for SendMessageJob.
=end
  SHUJAA_ERRORS = {
      0 => { :kind => :ok, :description => "Accepted for delivery (the message has been accepted by the gateway for delivery)" },
      1 => { :kind => :ok, :description => "Delivery success (the delivery to the destination address is successful)" },
      2 => { :kind => :message, :description => "Delivery failure (the delivery to the destination address has not been successful)" },
      4 => { :kind => :ok, :description => "Message buffered (the message has been queued for delivery)" },
      8 => { :kind => :ok, :description => "SMSC submit (the message has been submitted to the operator SMS gateway)" },
     16 => { :kind => :message, :description => "SMSC reject (the message has been rejected by the operator SMS gateway)" },
     32 => { :kind => :ok, :description => "SMSC intermediate notifications (intermediate notifications by the operator SMS gateway)" },
    200 => { :kind => :fatal, :description => "Unknown username (the username or email used to authenticate is not registered with the gateway)" },
    201 => { :kind => :fatal, :description => "Invalid password (the password supplied does not match the username)" },
    202 => { :kind => :fatal, :description => "Account not active (the account from which the send attempt has been made is not active, it may be in a suspended or deleted state)" },
    203 => { :kind => :message, :description => "Invalid destination address (the destination address is not a valid MSISDN or is a destination that is supported by the gateway)" },
    204 => { :kind => :fatal, :description => "Invalid source address (the source address is not allowed to be used by the particular account)" },
    205 => { :kind => :fatal, :description => "Invalid or missing parameters (not enough or invalid parameters have been provided when submitting a request to send a message)" },
    206 => { :kind => :temporary, :description => "Internal server error (an internal problem with the gateway is preventing the delivery of the message)" },
    207 => { :kind => :fatal, :description => "Insufficient credit (the user has exhausted the credits allowed for)" },
    208 => { :kind => :message, :description => "Invalid message (the message format is invalid, for example there is no content in the message)" },
    209 => { :kind => :message, :description => "Cannot route message (the phone number prefix provided is not in the range handled by this gateway)" },
  }
end
