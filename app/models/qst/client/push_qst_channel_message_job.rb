class PushQstChannelMessageJob < AbstractPushQstMessageJob

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
    @batch_size = 10
  end

  def account
    @account ||= Account.find_by_id(@account_id)
  end

  def channel
    @channel ||= account.find_channel @channel_id
  end

  def message_class
    AOMessage
  end

  def max_tries
    account.max_tries
  end

  def messages
    channel.ao_messages
  end

  def get_url_user_and_password
    [channel.configuration[:url], channel.configuration[:user], channel.configuration[:password]]
  end

  def save_last_id(last_id)
    channel.invalidate_queued_ao_messages_count
    channel.configuration[:last_ao_guid] = last_id
    channel.save!
  end

  def on_401(message)
    channel.logger.error :channel_id => channel.id, :message => message
    channel.enabled = false
    channel.save!
  end

  def on_exception(message)
    channel.logger.error :channel_id => channel.id, :message => message
  end
end
