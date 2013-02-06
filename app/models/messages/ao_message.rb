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

class AoMessage < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  has_many :logs
  has_many :children, :foreign_key => 'parent_id', :class_name => name

  validates_presence_of :account
  serialize :custom_attributes, Hash
  serialize :original, Hash

  after_save :send_delivery_ack
  before_save :route_failover

  include MessageCommon
  include MessageGetter
  include MessageSerialization
  include MessageCustomAttributes
  include MessageSearch

  # Logs that each message was delivered/not delivered through the given interface
  def self.log_delivery(msgs, account, interface)
    msgs.each do |msg|
      if msg.tries < account.max_tries
        account.logger.ao_message_delivery_succeeded msg, interface
      else
        account.logger.ao_message_delivery_exceeded_tries msg, interface
      end
    end
  end

  def send_succeed(account, channel, channel_relative_id = nil)
    self.state = 'delivered'
    self.channel_relative_id = channel_relative_id unless channel_relative_id.nil?
    self.save!

    account.logger.message_channeled self, channel
  end

  def send_failed(account, channel, exception)
    self.state = 'failed'
    self.save!

    account.logger.exception_in_channel_and_ao_message channel, self, exception
  end

  def reset_to_original
    return unless original.present?
    original.each do |key, value|
      if Fields.include? key.to_s
        self.send "#{key}=", value
      else
        self.custom_attributes[key.to_s] = value
      end
    end
  end

  private

  def send_delivery_ack
    return unless changed? && changes.keys != ["updated_at"]

    return true unless state == 'failed' || state == 'delivered' || state == 'confirmed'
    return true unless channel_id

    app = self.application
    return true unless app and app.delivery_ack_method != 'none'

    Queues.publish_application app, SendDeliveryAckJob.new(account_id, application_id, id, state)
    true
  end

  def route_failover
    return unless state_was != 'failed' && state == 'failed'
    return unless self.failover_channels.present?

    chans = self.failover_channels.split(',')
    chan = account.channels.find_by_id chans[0]

    self.failover_channels = chans[1 .. -1].join(',')
    self.failover_channels = nil if self.failover_channels.empty?

    return unless chan

    reset_to_original

    ThreadLocalLogger.reset
    ThreadLocalLogger << "Re-route failover"
    chan.route_ao self, 're-route', :dont_save => true
  end
end
