# Copyright (C) 2009-2012, InSTEDD
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

class ApiAuthenticatedController < ApplicationController
  skip_before_action :check_login
  skip_before_action :check_account
  before_action :authenticate_with_oauth2
  before_action :authenticate_with_basic

  def authenticate_with_basic
    return if @current_user || @account || @application

    authenticate_or_request_with_http_basic do |username, password|
      @account, @application = Account.authenticate username, password
      @account
    end
  end

  def authenticate_with_oauth2
    if req = guisso_request
      token = AltoGuissoRails.validate_oauth2_request(req) or return false

      # Find or create the user
      @current_user = User.find_by_email(token['user']) || begin
        User.create! email: token['user'], password: SecureRandom.base64, confirmed_at: Time.now
      end

      if params[:account]
        @account = @current_user.accounts.find_by_name(params[:account])
        unless @account
          return head :unauthorized
        end

        unless params[:application] == "-"
          # Find or create the OAuth client application
          @application = @account.applications.find_by_name(token['client']['name']) || begin
            @account.applications.create! name: token['client']['name'], password: SecureRandom.base64
          end
        end
      end
    end
  end

  def guisso_request
    env["guisso.oauth2.req"]
  end

  def require_account!
    unless @account
      return head :unauthorized
    end
  end

  def require_account_and_application!
    unless @account && @application
      return head :unauthorized
    end
  end
end
