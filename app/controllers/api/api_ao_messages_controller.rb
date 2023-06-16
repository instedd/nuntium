class ApiAoMessagesController < ApiAuthenticatedController
  before_filter :require_account_and_application!
  include AoMessageCreateCommon

  rescue_from(KeyError) { head :bad_request }

  def index
    ao_messages = AoMessage
      .where(application_id: @application.id, token: params.fetch(:token))
      .paginate(:page => params.fetch(:page, 1), :per_page => 50)
    respond ao_messages
  end

  def create
    create_from_request
  end

  private

  def respond(object)
    if page = object.next_page
      response.headers["Link"] = %(<#{api_ao_messages_url(token: params[:token], page: page)}>; rel="next")
    end

    respond_to do |format|
      format.xml { render :xml => object.to_xml(:root => 'ao_messages', :skip_types => true) }
      format.json { render :json => object }
    end
  end
end
