class ApiAoMessagesController < ApiAuthenticatedController
  before_filter :require_account_and_application!
  include AoMessageCreateCommon

  rescue_from(KeyError) { head :bad_request }

  def index
    ao_messages = AoMessage.find_all_by_application_id_and_token(@application.id, params.fetch(:token))
    respond ao_messages
  end

  def create
    create_from_request
  end

  private

  def respond(object)
    respond_to do |format|
      format.xml { render :xml => object.to_xml(:root => 'ao_messages', :skip_types => true) }
      format.json { render :json => object }
    end
  end
end
