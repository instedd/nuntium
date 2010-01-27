class SendAoController < ApplicationController

  before_filter :authenticate
  
  def create
    msg = AOMessage.new(
      :application_id => @application.id,
      :from => params[:from],
      :to => params[:to],
      :subject => params[:subject],
      :body => params[:body],
      :guid => params[:guid]
      )
    @application.route msg, 'http'
    
    if msg.state == 'error'
      render :text => 'error: ' + msg.id.to_s
    else
      render :text => 'id: ' + msg.id.to_s
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.find_by_name username
      !@application.nil? && @application.authenticate(password)
    end
  end

end