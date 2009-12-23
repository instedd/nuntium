class QSTController < ApplicationController
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.find_by_id_or_name(params[:application_id])
      if !@application.nil?
        @channel = @application.channels.find_by_name_and_kind username, 'qst'
        if !@channel.nil?
          @channel.handler.authenticate password
        else
          false
        end
      else
        false
      end
    end
  end
end