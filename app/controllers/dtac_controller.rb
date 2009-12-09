class DtacController < ApplicationController
  before_filter :authenticate

  def index  
	  msg = ATMessage.new
    msg.application_id = @application.id
    msg.from = 'sms://' + params[:MSISDN]
    msg.to = 'sms://' + params[:SMSCODE]
    msg.subject = params[:CONTENT]
    msg.guid = params[:ID]
    msg.timestamp = Time.now.utc
    msg.state = 'queued'
    msg.save!
    
    head :ok
  end
  
  def authenticate
    @application = Application.find_by_id(params[:application_id]) || Application.find_by_name(params[:application_id])
    return !@application.nil?
  end
  
end
