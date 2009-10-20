class QSTController < ApplicationController
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.first(:conditions => ['name = ?', params[:application_id]]) 
      if !@application.nil?
        @channel = @application.channels.first(:conditions => ['name = ? AND kind = ?', username, :qst])
        !@channel.nil? and @channel.configuration[:password] == password
      else
        false
      end
    end
  end
end