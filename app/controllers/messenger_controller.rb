# Copyright (C) 2009-2017, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class MessengerController < ApplicationController
  skip_filter :check_login
  before_filter :authenticate, :only => [:index]

  def index
    msg = AtMessage.new
    msg.from = params[:From]
    msg.to = params[:To]
    msg.body = params[:Body]
    @account.route_at msg, @channel

    head :ok
  end


  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      
      @account = Account.find_by_id_or_name(params[:account_id])
      if @account
        @channel = @account.messenger_channels.select do |c|
          c.configuration[:page_access_token] == params[:token] 
        end.first
      else
        false
      end
    end
  end
end
