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
  skip_filter :check_login
  before_filter :authenticate_with_oauth2
  before_filter :authenticate_with_basic

  def authenticate_with_basic
    return if @account && @application

    authenticate_or_request_with_http_basic do |username, password|
      @account, @application = Account.authenticate username, password
      @account
    end
  end

  def authenticate_with_oauth2
    if req = guisso_request
      token = AltoGuissoRails.validate_oauth2_request(req) or return false

      # Find or create the user
      user = User.find_by_email(token['user']) || begin
        User.create! email: token['user'], password: SecureRandom.base64, confirmed_at: Time.now
      end

      # Find or create the default account for the user
      @account = user.accounts.find_by_name(user.email) || begin
        account = Account.create! name: user.email, password: SecureRandom.base64
        user.create_account account
        account
      end

      # Find or create the OAuth client application
      @application = @account.applications.find_by_name(token['client']['name']) || begin
        @account.applications.create! name: token['client']['name'], password: SecureRandom.base64
      end
    end
  end

  def guisso_request
    env["guisso.oauth2.req"]
  end

end
