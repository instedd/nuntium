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

require 'blather/client/dsl'

class XmppService < ChannelService
end

class XmppConnection
  include Blather::DSL

  PrefetchCount = 5

  def initialize(channel)
    @channel = channel
    @mq = MQ.new
    @mq.prefetch PrefetchCount
    @online_contacts = Set.new
  end

  def start
    if !@channel.check_valid_in_ui
      @channel.alert "Invalid credentials"
      @channel.enabled = false
      @channel.save!

      @mq.close
      return false
    end

    @is_running = true

    setup @channel.jid, @channel.password, @channel.server, @channel.port
    when_ready do
      Rails.logger.info "Connected to #{@channel.jid}"
      self.channel_connected = true

      set_status :chat, @channel.status if @channel.status.present?
      subscribe_queue
    end

    receive_chats
    receive_errors
    receive_subscriptions
    receive_presence unless @channel.send_if_user_is_offline?
    handle_disconnections

    client.run
    true
  end

  def stop
    @is_running = false
    @mq.close
    client.close
    self.channel_connected = false
  end

  def receive_chats
    message :chat?, :body do |msg|
      begin
        at = AtMessage.new
        at.channel_relative_id = msg.id
        at.from = msg.from.stripped.to_s.with_protocol 'xmpp'
        at.to = msg.to.stripped.to_s.with_protocol 'xmpp'
        at.subject = msg.subject
        at.body = msg.body

        @channel.route_at at
      rescue Exception => ex
        Rails.logger.error "[#{@channel.name}] Error delivering incoming message: #{ex.message} - #{ex.backtrace}"
      end
      true
    end
  end

  def receive_errors
    message :error? do |msg|
      ao = AoMessage.find_by_id msg.id
      if ao
        ao.state = 'failed'
        ao.save!

        @channel.logger.exception_in_channel_and_ao_message @channel, ao, "#{msg}"
      else
        Rails.logger.debug "[#{@channel.name}] Received error message: #{msg}"
      end
    end
  end

  def receive_subscriptions
    subscription :request? do |s|
      @channel.logger.info :message => "[#{@channel.name}] Accepting subscription from #{s.from}", :application_id => @channel.application_id, :channel_id => @channel.id

      write_to_stream s.approve!
    end
  end

  def receive_presence
    presence do |status|
      if status.type.blank?
        @online_contacts.add status.from.stripped.to_s
      elsif status.type == "unavailable" || status.type == :unavailable
        @online_contacts.delete status.from.stripped.to_s
      end
    end
  end

  def handle_disconnections
    disconnected do
      self.channel_connected = false

      if @is_running
        Rails.logger.info "[#{@channel.name}] Disconnected, trying to reconnect..."
        client.connect
      end

      true
    end
  end

  def send_message(id, from, to, subject, body)
    unless @channel.send_if_user_is_offline?
      unless @online_contacts.include? to
        raise MessageException.new "User #{to} is offline"
      end
    end

    Rails.logger.debug "[#{@channel.name}] Sending message with id: '#{id}', from: '#{from}', to: '#{to}', subject: '#{subject}', body: '#{body}'"

    msg = Blather::Stanza::Message.new
    msg.id = id
    msg.to = to
    if body.empty?
      msg.body = subject
    else
      msg.subject = subject
      msg.body = body
    end
    msg.type = :chat

    write_to_stream msg
  end

  def subscribe_queue
    Rails.logger.info "[#{@channel.name}] Subscribing to message queue"

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      Rails.logger.debug "[#{@channel.name}] Executing job #{job}"
      begin
        job.perform self
        header.ack
      rescue Exception => ex
        Rails.logger.info "[#{@channel.name}] Exception executing #{job}: #{ex.class} #{ex} #{ex.backtrace}"
        reschedule job, header, ex
      end
    end

    @subscribed = true
  end

  def reschedule(job, header, ex)
    job.reschedule ex
  rescue => ex
    Rails.logger.info "[#{@channel.name}] Exception rescheduling #{job}: #{ex.class} #{ex} #{ex.backtrace}"
    unsubscribe_temporarily
  else
    header.ack
  end

  def unsubscribe_temporarily
    if @subscribed
      unsubscribe_queue
      EM.add_timer(5) { subscribe_queue }
    end
  end

  def unsubscribe_queue
    Rails.logger.info "[#{@channel.name}] Unsubscribing from message queue"

    @mq = Queues.reconnect(@mq)
    @mq.prefetch PrefetchCount

    @subscribed = false
  end

  def channel_connected=(value)
    @connected = value
    @channel.connected = value
  end

  def notify_connection_status
    @channel.connected = @connected
  end
end
