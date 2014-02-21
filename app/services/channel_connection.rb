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

module ChannelConnection
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

  def channel_connected=(value)
    @connected = value
    @channel.connected = value
  end

  def notify_connection_status
    @channel.connected = @connected
  end

  def alert_user_if_couldnt_reconnect_soon
    EM.add_timer(60) do
      unless @connected
        @channel.notify_disconnected
        @alert_on_reconnect = true
      end
    end
  end

  def check_alert_on_reconnect
    if @alert_on_reconnect
      @channel.notify_reconnected
      @alert_on_reconnect = false
    end
  end
end
