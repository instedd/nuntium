class SendAoController < ApplicationController

  before_filter :authenticate
  
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

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name params[:account_name]
      if @account
        @application = Application.first :conditions => ['account_id = ? AND name = ?', @account.id, username]
        if @application and @application.authenticate password
          @application.account = @account
          true
        else
          false
        end
      else
        false
      end
    end
  end

end
