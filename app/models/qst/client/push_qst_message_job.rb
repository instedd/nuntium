class PushQstMessageJob < AbstractPushQstMessageJob
  include ApplicationQstConfiguration

  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end

  def message_class
    ATMessage
  end

  def max_tries
    account.max_tries
  end

  def messages
    account.at_messages
  end

  def save_last_id(last_id)
    application.last_at_guid = last_id
    application.save!
  end
end
