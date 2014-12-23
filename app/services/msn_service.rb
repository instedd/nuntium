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

Msn::Messenger.logger = Rails.logger

class MsnService < ChannelService
end

class MsnConnection
  include Msn
  include ChannelConnection

  PrefetchCount = 5

  def initialize(channel)
    @channel = channel
    @mq = Queues.new_mq
    @mq.prefetch PrefetchCount
    @message_ids = {}
  end

  def start
    @is_running = true

    @msn = Messenger.new @channel.email, @channel.password
    @msn.on_login_failed do |message|
      @channel.logger.error :message => "[#{@channel.name}] Login failed: #{message}", :application_id => @channel.application_id, :channel_id => @channel.id
      stop
    end
    @msn.on_ready do
      self.channel_connected = true

      @msn.set_online_status :online
      check_pending_contacts
      subscribe_queue

      check_alert_on_reconnect
    end

    receive_messages
    receive_acks
    receive_subscriptions
    handle_disconnections

    @msn.connect
    true
  end

  def stop
    @is_running = false
    @mq.close
    @msn.close
    self.channel_connected = false
  end

  def check_pending_contacts
    @msn.get_contacts.each do |contact|
      if contact.pending
        @channel.logger.info :message => "[#{@channel.name}] Accepting contact request from #{contact.email} (#{contact.display_name})", :application_id => @channel.application_id, :channel_id => @channel.id

        @msn.add_to_friends_list contact.email
        @msn.add_to_allowed_list contact.email
      end
    end
  end

  def receive_messages
    @msn.on_message do |msg|
      begin
        at = AtMessage.new
        at.from = msg.email.with_protocol 'msn'
        at.to = @channel.email.with_protocol 'msn'
        at.body = msg.text

        @channel.route_at at
      rescue Exception => ex
        Rails.logger.error "[#{@channel.name}] Error delivering incoming message: #{ex.message} - #{ex.backtrace}"
      end
    end
  end

  def receive_subscriptions
    @msn.on_contact_request do |email, display_name|
      @channel.logger.info :message => "[#{@channel.name}] Accepting contact request from #{email} (#{display_name})", :application_id => @channel.application_id, :channel_id => @channel.id

      @msn.add_to_friends_list email
      @msn.add_to_allowed_list email
    end
  end

  def handle_disconnections
    @msn.on_disconnect do
      was_connected = @connected
      self.channel_connected = false

      if @is_running
        alert_user_if_couldnt_reconnect_soon if was_connected

        Rails.logger.info "[#{@channel.name}] Disconnected, trying to reconnect..."
        @msn.connect
      end
    end
  end

  def send_message(id, from, to, subject, body)
    Rails.logger.debug "[#{@channel.name}] Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"

    message_id = @msn.send_message to, body
    @message_ids[message_id] = id
  end

  def receive_acks
    @msn.on_message_ack do |message_id, status|
      id = @message_ids.delete(message_id)
      if id && (msg = AoMessage.find id)
        msg.state = status == :ack ? 'confirmed' : 'failed'
        msg.save!

        message = case status
                  when :ack then "Received ACK"
                  when :nak then "Received NAK"
                  when :offline then "User if offline"
                  end

        @channel.logger.info :ao_message_id => msg.id, :message => message, :application_id => @channel.application_id, :channel_id => @channel.id
      end
    end
  end

  def subscribe_queue
    Rails.logger.info "[#{@channel.name}] Subscribing to message queue"

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      EM.schedule {
        Rails.logger.debug "[#{@channel.name}] Executing job #{job}"
        begin
          job.perform self
          header.ack
        rescue Exception => ex
          Rails.logger.info "[#{@channel.name}] Exception executing #{job}: #{ex.class} #{ex} #{ex.backtrace}"
          reschedule job, header, ex
        end
      }
    end

    @subscribed = true
  end

  def unsubscribe_queue
    Rails.logger.info "[#{@channel.name}] Unsubscribing from message queue"

    @mq = Queues.recycle_mq(@mq)
    @mq.prefetch PrefetchCount

    @subscribed = false
  end
end
