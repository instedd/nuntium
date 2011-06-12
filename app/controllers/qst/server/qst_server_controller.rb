class QSTServerController < ApplicationController
  before_filter :authenticate
  before_filter :update_channel_last_activity_at

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if @account
        @channel = @account.channels.select{|c| c.name == username && c.kind == 'qst_server'}.first
        if @channel
          @channel.handler.authenticate password
        else
          false
        end
      else
        false
      end
    end
  end

  def update_channel_last_activity_at
    @channel.last_activity_at = Time.now.utc
    @channel.save!
  end
end
