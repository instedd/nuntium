class PullQstChannelMessageJob < AbstractPullQstMessageJob
  include ChannelQstConfiguration

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
    @batch_size = 10
  end

  def message_class
    AtMessage
  end

  def load_last_id
    channel.last_at_guid
  end

  def save_last_id(last_id)
    channel.last_at_guid = last_id
    channel.save!
  end

  def route(msg)
    account.route_at msg, channel
  end
end
