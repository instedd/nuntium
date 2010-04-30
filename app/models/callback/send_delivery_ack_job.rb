require 'uri'
require 'net/http'
require 'net/https'
include ActiveSupport::Multibyte

class SendDeliveryAckJob
  attr_accessor :account_id, :application_id, :message_id, :state

  def initialize(account_id, application_id, message_id, state)
    @account_id = account_id
    @application_id = application_id
    @message_id = message_id
    @state = state
  end

  def perform
  end
end
