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

# coding: utf-8

class MultimodemIsmsChannel < Channel
  include CronChannel
  include GenericChannel

  configuration_accessor :host, :user, :password, :time_zone
  configuration_accessor :port, :default => 81

  validates_presence_of :host, :port, :user, :password
  validates_numericality_of :port, :greater_than => 0

  def self.title
    "Multimodem iSms"
  end

  def self.default_protocol
    'sms'
  end

  def info
    port.present? ? "#{user}@#{host}:#{port}" : "#{user}@#{host}"
  end

  def create_tasks
    create_task 'multimodem-isms-receive', MULTIMODEM_ISMS_RECEIVE_INTERVAL, ReceiveMultimodemIsmsMessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'multimodem-isms-receive'
  end

  ERRORS = {
    601 => { :kind => :fatal, :description => 'Authentication Failed Send API, Query API'},
    602 => { :kind => :fatal, :description => 'Parse Error Send API, Query API'},
    603 => { :kind => :fatal, :description => 'Invalid Category Send API'},
    604 => { :kind => :message, :description => 'SMS message size is greater than 160 chars Send API'},
    605 => { :kind => :fatal, :description => 'Recipient Overflow Send API'},
    606 => { :kind => :message, :description => 'Invalid Recipient Query API'},
    607 => { :kind => :message, :description => 'No Recipient Send API'},
    608 => { :kind => :unexpected, :description => 'MultiModem iSMS is busy, can’t accept this request Send API, Query API'},
    609 => { :kind => :unexpected, :description => 'Timeout waiting for a TCP API request Send API'},
    610 => { :kind => :unexpected, :description => 'Unknown Action Trigger Send API'},
    611 => { :kind => :unexpected, :description => 'Error in broadcast trigger Send API'},
    612 => { :kind => :unexpected, :description => 'System Error – Memory Allocation Failure Send API, Query API'},
    613 => { :kind => :fatal, :description => 'Invalid Modem Index'},
    614 => { :kind => :fatal, :description => 'Invalid device model number'},
    615 => { :kind => :message, :description => 'Invalid Encoding type Send API'},
    616 => { :kind => :message, :description => 'Invalid Time/Date Input Receive API'},
    617 => { :kind => :message, :description => 'Invalid Count Input Receive API'},
    618 => { :kind => :fatal, :description => 'Service Not Available (Non-Polling Receive API is enabled so Polling Receive API service is not available)'},
    619 => { :kind => :message, :description => 'Invalid Addressee Receive API'},
    620 => { :kind => :message, :description => 'Invalid Priority value Send API'},
    621 => { :kind => :message, :description => 'Invalid SMS text'}
  }
end
