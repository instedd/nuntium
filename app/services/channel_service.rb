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

class ChannelService < Service
  def initialize
    @notifications_session = MQ.new
    @connections = {}
  end

  def start
    start_connections
    subscribe_to_notifications
    notify_connection_status_loop
  end

  def start_connections
    channel_class.active.each do |channel|
      start_channel channel
    end
  end

  def subscribe_to_notifications
    Queues.subscribe_notifications(kind, kind, @notifications_session) do |header, job|
      job.perform self
    end
  end

  def notify_connection_status_loop
    EM.add_periodic_timer 1.minute do
      @connections.each_value &:notify_connection_status
    end
  end

  def start_channel(channel)
    channel = Channel.find channel unless channel.is_a? Channel
    connection = connection_class.new channel
    if connection.start
      @connections[channel.id] = connection
    end
  end

  def stop_channel(id)
    connection = @connections.delete id
    connection.stop if connection
  end

  def restart_channel(id)
    stop_channel id
    start_channel id
  end

  def stop
    stop_connections
    EM.stop_event_loop
  end

  def stop_connections
    @connections.each &:stop
  end

  def identifier
    self.class.name =~ /(.*)Service/
    $1
  end

  def kind
    identifier.underscore
  end

  def channel_class
    "#{identifier}Channel".constantize
  end

  def connection_class
    "#{identifier}Connection".constantize
  end
end
