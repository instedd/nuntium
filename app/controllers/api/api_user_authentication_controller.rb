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

class ApiUserAuthenticationController < ApplicationController
  skip_filter :check_login

  before_filter :authenticate, :except => :request_token
  def authenticate
    authenticate_or_request_with_http_basic do |username, token|
      @user = User.authenticate username, token
      @user
    end
  end

  def request_token
    email = params[:email]
    password = params[:password]

    if email.nil? or password.nil?
      render  :status=>400,
              :json=>{:message=>"The request must contain the user email and password."}
      return
    end

    @user=User.find_by_email(email.downcase)

    if @user.nil?
      logger.info("User #{email} failed signin, user cannot be found.")
      render :status=>401, :json=>{:message=>"Invalid email or password."}
      return
    end

    if not @user.valid_password?(password)
      logger.info("User #{email} failed signin, password \"#{password}\" is invalid")
      render :status=>401, :json=>{:message=>"Invalid email or password."}
    else
      authentication_token = Digest::SHA1.hexdigest([Time.now, rand].join)
      @user.authentication_token = authentication_token
      @user.save!
      render :status=>200, :text => authentication_token , :layout => false
    end
  end

end