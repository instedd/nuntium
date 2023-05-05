class ApiAoMessagesController < ApiAuthenticatedController
  before_filter :require_account_and_application!
  include AoMessageCreateCommon

  rescue_from(KeyError) { head :bad_request }

  def index
    render :json => AoMessage.find_all_by_application_id_and_token(@application.id, params.fetch(:token))
  end

  def create
    create_from_request
  end
end
