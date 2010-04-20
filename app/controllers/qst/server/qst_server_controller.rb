class QSTServerController < ApplicationController
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if !@account.nil?
        @channel = @account.channels.find_by_name_and_kind username, 'qst_server'
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
