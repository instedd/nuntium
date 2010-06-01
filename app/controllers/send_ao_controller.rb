class SendAoController < ApplicationAuthenticatedController

  # GET /:account_name/:application_name/send_ao
  def create
    msg = AOMessage.from_hash params
    msg.account_id = @account.id
    @application.route_ao msg, 'http'
    
    if msg.state == 'failed'
      render :text => "error: #{msg.id}"
    else
      render :text => "id: #{msg.id}"
    end
  end

end
