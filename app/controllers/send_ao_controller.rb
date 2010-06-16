class SendAoController < ApplicationAuthenticatedController

  # GET /:account_name/:application_name/send_ao
  def create
    msg = AOMessage.from_hash params
    msg.account_id = @account.id
    @application.route_ao msg, 'http'
    
    response.headers['X-Nuntium-Id'] = msg.id.to_s
    response.headers['X-Nuntium-Guid'] = msg.guid.to_s
    head msg.state == 'failed' ? :bad_request : :ok
  end

end
