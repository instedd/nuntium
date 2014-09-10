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

require 'test_helper'

class ApiUserAuthenticationControllerTest < ActionController::TestCase
  def setup
    User.make :email => 'fakeemail@testing.com', :password=>'password', :password_confirmation => 'password',:authentication_token => '123456'
  end

  test "request token" do
    get :request_token, :email => 'fakeemail@testing.com', :password => 'password'
    assert_response :ok
    assert_not_equal '123456', User.find_by_email('fakeemail@testing.com').authentication_token
  end

end