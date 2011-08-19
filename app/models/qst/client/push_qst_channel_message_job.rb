class PushQstChannelMessageJob < AbstractPushQstMessageJob
  include ChannelQstConfiguration

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
    @batch_size = 10
  end

  def message_class
    AoMessage
  end

  def max_tries
    account.max_tries
  end

  def messages
    channel.ao_messages
  end

  def save_last_id(last_id)
    channel.configuration[:last_ao_guid] = last_id
    channel.save!
  end
end
