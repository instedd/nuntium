class PullQstMessageJob < AbstractPullQstMessageJob
  include ApplicationQstConfiguration

  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end

  def message_class
    AOMessage
  end

  def load_last_id
    application.last_ao_guid
  end

  def save_last_id(last_id)
    application.last_ao_guid = last_id
    application.save!
  end

  def route(msg)
    application.route_ao msg, 'qst_client'
  end
end
