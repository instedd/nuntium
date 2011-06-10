class GetAoController < ApplicationAuthenticatedController
  # GET /:account_name/:application_name/get_ao.:format
  def index
    ao_messages = AOMessage.find_all_by_application_id_and_token @application.id, params[:token]
    render :json => ao_messages
  end
end
