class SendAoController < ApplicationController

  before_filter :authenticate
  
  def create
    msg = AOMessage.new(
      :account_id => @account.id,
      :from => params[:from],
      :to => params[:to],
      :subject => params[:subject],
      :body => params[:body],
      :guid => params[:guid]
      )
    @account.route msg, 'http'
    
    if msg.state == 'error'
      render :text => "error: #{msg.id}"
    else
      render :text => "id: #{msg.id}"
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_name username
      !@account.nil? && @account.authenticate(password)
    end
  end

end
