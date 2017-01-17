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

# Server equivalent of SmppGateway class
class SmppServerGateway < SmppTransceiverDelegate
  include ChannelConnection

  def initialize(transceiver, channel)
    super
    @prefetch_count = channel.max_unacknowledged_messages.to_i
    @prefetch_count = 5 if @prefetch_count <= 0
    @pending_headers = {}
    @subscribed = false
    @channel = channel

    @suspension_codes = [Smpp::Pdu::Base::ESME_RMSGQFUL, Smpp::Pdu::Base::ESME_RTHROTTLED]
    @suspension_codes += channel.suspension_codes_as_array

    @rejection_codes = [Smpp::Pdu::Base::ESME_RINVSRCADR, Smpp::Pdu::Base::ESME_RINVDSTADR]
    @rejection_codes += channel.rejection_codes_as_array

    self.channel_connected = true
    subscribe_queue
    check_alert_on_reconnect
  end

  def stop
    Rails.logger.info "[#{@channel.name}] Closing SMPP connection"
    self.channel_connected = false
    @transceiver.close_connection
    unsubscribe_queue
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    super
    send_ack mt_message_id
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    case pdu.command_status

    # Queue full
    when *@suspension_codes
      Rails.logger.info "[#{@channel.name}] Received ESME_RMSGQFUL or ESME_RHTORTTLED (#{pdu.command_status})"
      unsubscribe_temporarily

    # Message source or address not valid
    when *@rejection_codes
      super
      send_ack mt_message_id

    # Disable channel and alert
    else
      alert_msg = "Received command status #{pdu.command_status} in smpp channel #{@channel.name} (#{@channel.id})"

      Rails.logger.warn alert_msg
      @channel.alert alert_msg

      @channel.enabled = false
      @channel.save!

      stop
    end
  end

  def unbound(transceiver)
    Rails.logger.info "[#{@channel.name}] Delegate: transceiver unbound"
    self.channel_connected = false
    unsubscribe_queue
  end

  def subscribe_queue
    Rails.logger.info "[#{@channel.name}] Subscribing to message queue"

    @mq = Queues.new_mq
    @mq.prefetch @prefetch_count
    @mq.on_error { |err| Rails.logger.error err }

    Queues.subscribe_ao(@channel, @mq) do |header, job|
      EM.schedule {
        Rails.logger.debug "[#{@channel.name}] Executing job #{job}"
        begin
          if job.perform(self)
            @pending_headers[job.message_id] = header
          else
            header.ack
          end
        rescue Exception => ex
          Rails.logger.info "[#{@channel.name}] Error when performing job. Exception: #{ex.class} #{ex}"
          reschedule job, header, ex
        end

        sleep_time
      }
    end

    @subscribed = true
  end

  def unsubscribe_queue
    Rails.logger.info "[#{@channel.name}] Unsubscribing from message queue"

    @mq.close unless @mq.nil?
    @mq = nil

    @subscribed = false
  end

  def send_ack(message_id)
    header = @pending_headers.delete(message_id)
    if header
      header.ack
    else
      Rails.logger.error "[#{@channel.name}] Pending header not found for message id: #{message_id}"
    end
  end

  def sleep_time
    if @channel.throttle and @channel.throttle > 0
      sleep(60.0 / @channel.throttle)
    end
  end
end
