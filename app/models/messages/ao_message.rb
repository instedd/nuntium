class AOMessage < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  validates_presence_of :account
  serialize :custom_attributes, Hash
  serialize :original, Hash

  after_save :send_delivery_ack
  after_save :update_queued_ao_messages_count
  before_save :route_failover

  include MessageCommon
  include MessageGetter
  include MessageState

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

  def send_succeeed(account, channel, channel_relative_id = nil)
    self.state = 'delivered'
    self.tries += 1
    self.channel_relative_id = channel_relative_id unless channel_relative_id.nil?
    self.save!

    account.logger.message_channeled self, channel
  end

  def send_failed(account, channel, exception)
    self.tries += 1
    self.state = 'failed'
    self.save!

    account.logger.exception_in_channel_and_ao_message channel, self, exception
  end

  def reset_to_original
    return unless original.present?
    original.each do |key, value|
      if ['from', 'to', 'subject', 'body'].include? key.to_s
        self.send "#{key}=", value
      else
        self.custom_attributes[key.to_s] = value
      end
    end
  end

  private

  def send_delivery_ack
    return unless changed?

    return true unless state == 'failed' || state == 'delivered' || state == 'confirmed'
    return true unless channel_id

    app = self.application
    return true unless app and app.delivery_ack_method != 'none'

    Queues.publish_application app, SendDeliveryAckJob.new(account_id, application_id, id, state)
    true
  end

  def update_queued_ao_messages_count
    if channel_id
      if state_was != 'queued' && state == 'queued'
        found = Rails.cache.increment Channel.queued_ao_messages_count_cache_key(channel_id)
        Channel.initialize_queued_ao_messages_count channel_id unless found
      elsif state_was == 'queued' && state != 'queued'
        found = Rails.cache.decrement Channel.queued_ao_messages_count_cache_key(channel_id)
        Channel.initialize_queued_ao_messages_count channel_id unless found
      end
    end
  end

  def route_failover
    return unless state_was != 'failed' && state == 'failed'
    return unless self.candidate_channels.present?

    chans = self.candidate_channels.split(',')
    return unless chans.present?

    chans = chans[1 .. -1]
    self.candidate_channels = chans.join(',')
    self.candidate_channels = nil if self.candidate_channels.empty?

    return unless self.candidate_channels

    chan = account.find_channel chans[0]
    return unless chan

    reset_to_original

    ThreadLocalLogger.reset
    ThreadLocalLogger << "Re-route failover"
    chan.route_ao self, 're-route', :dont_save => true
  end

end
