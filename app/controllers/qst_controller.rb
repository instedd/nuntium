require 'digest/sha2'

class QSTController < ApplicationController
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.first(
        :conditions => ['name = ?', params[:application_id]])
      if !@application.nil?
        @channel = @application.channels.first(
          :conditions => ['name = ? AND kind = ?', username, :qst])
        if !@channel.nil?
          real_salt = @channel.configuration[:salt]
          real_pass = @channel.configuration[:password]
          real_pass == Digest::SHA2.hexdigest(real_salt + password)
        else
          false
        end
      else
        false
      end
    end
  end
end