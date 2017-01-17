# encoding: UTF-8

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

# Heavily inspired in Smpp::Server from ruby-smpp
class SmppServer < Smpp::Base

  attr_accessor :bind_status

  def initialize(config, service)
    super(config, nil)
    @state = :unbound
    @service = service
    @received_messages = []
    @sent_messages = []

    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = [ed - 5, 3].max
  rescue Exception => ex
    logger.error "Exception setting up server: #{ex}"
    raise
  end


  #######################################################################
  # Session management functions
  #######################################################################
  # Session helpers

  # is this session currently bound?
  def bound?
    @state == :bound
  end

  # is this session currently unbound?
  def unbound?
    @state == :unbound
  end

  # set of valid bind statuses
  BIND_STATUSES = {:transmitter => :bound_tx,
           :receiver => :bound_rx, :transceiver => :bound_trx}

  # set the bind status based on the common-name for the bind class
  def set_bind_status(bind_classname)
    @bind_status = BIND_STATUSES[bind_classname]
  end

  # and kill the bind status when done
  def unset_bind_status
    @bind_status = nil
  end

  # what is the bind_status?
  def bind_status
    @bind_status
  end

  # convenience function - are we able to transmit in this bind-Status?
  def transmitting?
    # not transmitting if not bound
    return false if unbound? || bind_status.nil?
    # receivers can't transmit
    bind_status != :bound_rx
  end

  # convenience function - are we able to receive in this bind-Status?
  def receiving?
    # not receiving if not bound
    return false if unbound? || bind_status.nil?
    # transmitters can't receive
    bind_status != :bound_tx
  end

  def am_server?
    true
  end

  def fetch_bind_response_class(bind_classname)
    # check we have a valid classname - probably overkill as only our code will send the classnames through
    raise IOError, "bind class name missing" if bind_classname.nil?
    raise IOError, "bind class name: #{bind_classname} unknown" unless BIND_STATUSES.has_key?(bind_classname)

    case bind_classname
    when :transceiver
      return Smpp::Pdu::BindTransceiverResponse
    when :transmitter
      return Smpp::Pdu::BindTransmitterResponse
    when :receiver
      return Smpp::Pdu::BindReceiverResponse
    end
  end

  # Actually perform the action of binding the session to the given session type
  def bind_session(bind_pdu, bind_classname)
    raise IOError, "Session already bound." if bound?
    response_class = fetch_bind_response_class(bind_classname)

    # Load channel from system id, ensuring the class is properly loaded (thanks, Ruby)
    Channel; BaseSmppChannel; SmppServerChannel
    channel = SmppServerChannel.find_by_system_id(bind_pdu.system_id)
    if channel.nil?
      send_bind_response(Pdu::Base::ESME_RINVSYSID, bind_pdu, response_class)
      return
    end

    # Authenticate
    if !channel.check_password(bind_pdu.password)
      send_bind_response(Pdu::Base::ESME_RINVPASWD, bind_pdu, response_class)
      return
    end

    # Bind and set delegate from channel
    logger.info("Bound channel #{channel.class} #{channel.id}")
    send_bind_response(Pdu::Base::ESME_ROK, bind_pdu, response_class)
    @state = :bound
    set_bind_status(bind_classname)
    @delegate = SmppServerGateway.new(self, channel)
    update_config_from(channel)
  end

  def update_config_from(channel)
    @config[:system_type] = channel.system_type
    @config[:interface_version] = 52
    @config[:source_ton] = channel.source_ton.to_i
    @config[:source_npi] = channel.source_npi.to_i
    @config[:destination_ton] = channel.destination_ton.to_i
    @config[:destination_npi] = channel.destination_npi.to_i
  end

  # Send BindReceiverResponse PDU - used in response to a "bind_receiver" pdu
  def send_bind_response(response, bind_pdu, bind_class)
    resp_pdu = bind_class.new(bind_pdu.sequence_number, response, bind_pdu.system_id)
    write_pdu(resp_pdu)
  end

  #######################################################################
  # Message submission (transmitter) functions (used by transmitter and
  # transceiver-bound system)
  # Note - we only support submit_sm message type, not submit_multi or
  # data_sm message types
  #######################################################################
  # Receive an incoming message to send to the network and respond
  def receive_sm(pdu)
    raise IOError, "Connection not bound." if unbound?
    # Doesn't matter if it's a TX/RX/TRX, have to send a SubmitSmResponse:
    # raise IOError, "Connection not set to receive" unless receiving?

    # Must respond to SubmitSm requests with the same sequence number
    m_seq = pdu.sequence_number

    # Do something useful with the message
    message_id = if @delegate.respond_to?(:mo_received)
      @delegate.mo_received(self, pdu).try(:id)
    end

    pdu = Pdu::SubmitSmResponse.new(m_seq, Pdu::Base::ESME_ROK, message_id)
    write_pdu pdu
    logger.info "Received submit sm message: #{m_seq}"
  end

  #######################################################################
  # Message delivery (receiver) functions (used by receiver and
  # transceiver-bound system)
  #######################################################################
  # When we get an incoming SMS to send on to the client, we need to initiate one of these PDUs
  def send_mt(message_id, from, to, message, config = {})
    raise IOError, "Connection not bound." if unbound?
    raise IOError, "Connection not set to receive" unless receiving?

    # submit the given message
    config[:receipted_message_id] = message_id
    new_pdu = Pdu::DeliverSm.new(from, to, message, config)
    write_pdu(new_pdu)

    @ack_ids[new_pdu.sequence_number] = message_id
    logger.info "Delivered SM message seq: #{new_pdu.sequence_number}"
    new_pdu
  end

  # Acknowledge delivery of an outgoing MO message
  # TODO: Wire this method?
  def accept_deliver_sm_response(pdu)
    logger.info "Acknowledged receipt of SM delivery message seq: #{m_seq}"
    if @delegate.respond_to?(:delivery_report_received)
      @delegate.delivery_report_received(self, pdu)
    end
  end

  # A PDU is received
  # these pdus are all responses to a message sent by the client and require
  # their own special response
  def process_pdu(pdu)
    case pdu
    # client has asked to set up a connection
    when Pdu::BindTransmitter
      bind_session(pdu, :transmitter)
    when Pdu::BindReceiver
      bind_session(pdu, :receiver)
    when Pdu::BindTransceiver
      bind_session(pdu, :transceiver)
    when Pdu::DeliverSmResponse
      mt_message_id = @ack_ids.delete(pdu.sequence_number)
      if !mt_message_id
        logger.error "Got DeliverSmResponse for unknown sequence_number: #{pdu.sequence_number}"
      elsif pdu.command_status != Pdu::Base::ESME_ROK
        logger.error "Error status in DeliverSmResponse: #{pdu.command_status}"
        if @delegate.respond_to?(:message_rejected_by_client)
          @delegate.message_rejected_by_client(self, mt_message_id)
        end
      else
        logger.info "Got OK DeliverSmResponse (#{pdu.sequence_number} -> #{mt_message_id})"
        if @delegate.respond_to?(:message_accepted_by_client)
          @delegate.message_accepted_by_client(self, mt_message_id)
        end
      end
    when Pdu::SubmitSm
      receive_sm(pdu)
    else
      # for generic functions or default fallback
      super(pdu)
    end
  end

end
