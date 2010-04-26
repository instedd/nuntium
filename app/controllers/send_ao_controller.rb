class SendAoController < ApplicationAuthenticatedController

  # GET /send_ao/:account_name
  def create
    msg = AOMessage.new(
      :account_id => @account.id,
      :from => params[:from],
      :to => params[:to],
      :subject => params[:subject],
      :body => params[:body],
      :guid => params[:guid]
      )
    @application.route msg, 'http'
    
    if msg.state == 'error'
      render :text => "error: #{msg.id}"
    else
      render :text => "id: #{msg.id}"
    end
  end

end
