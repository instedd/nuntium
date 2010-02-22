class DtacController < ApplicationController
  before_filter :authenticate
	require 'iconv'
  
  def index  
  	converter = Iconv.new('UTF-8','TIS-620')
  	text = converter.iconv(params[:CONTENT])
  	
  	msg = ATMessage.new
    msg.from = "sms://#{params[:MSISDN]}"
    msg.to = "sms://#{params[:SMSCODE]}"
    msg.body = text
    msg.channel_relative_id = params[:ID]
    msg.timestamp = Time.now.utc
    
    @application.accept msg, nil
    
    head :ok
  end
  
  def authenticate
    @application = Application.find_by_id_or_name(params[:application_id])
    return !@application.nil?
  end
  
end
