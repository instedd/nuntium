class ClickatellController < ApplicationController
  before_filter :authenticate

  # GET /clickatell/:application_id/incoming
  def index
    msg = ATMessage.new
    msg.application_id = @application.id
    msg.from = 'sms://' + params[:from]
    msg.to = 'sms://' + params[:to]
    msg.subject = params[:text]
    msg.guid = params[:moMsgId]
    msg.timestamp = Time.at(params[:timestamp].to_i)
    msg.state = 'queued'
    msg.save!
    
    head :ok
  end
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.find_by_id(params[:application_id]) || Application.find_by_name(params[:application_id])
      if !@application.nil?
        channels = @application.channels.find_all_by_kind 'clickatell'
        channels = channels.select { |c| 
          c.name == username && 
          c.configuration[:incoming_password] == password &&
          c.configuration[:api_id] == params[:api_id] }
        if channels.empty?
          false
        else
          @channel = channels[0]
          true
        end
      else
        false
      end
    end
  end
end
