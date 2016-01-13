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

class ApiTwitterChannelControllerTest < ActionController::TestCase
  [nil, false, true].each do |follow|
    test "account authenticated with follow #{follow}" do
      @account = Account.make! :password => 'secret'
      @channel = TwitterChannel.make! :account => @account

      client = mock('client')
      client.expects(:follow).with('foo', follow: follow.to_b)

      TwitterChannel.expects(:new_authorized_client).with(@channel.token, @channel.secret, TwitterChannel.consumer_key, TwitterChannel.consumer_secret).returns(client)

      @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
      get :friendship_create, :name => @channel.name, :user => 'foo', :follow => follow

      assert_response :ok
    end
  end

  test "application authenticated" do
    @account = Account.make! :password => 'secret'
    @application = Application.make! :account => @account, :password => 'secret2'
    @channel = TwitterChannel.make! :account => @account, :application => @application

    client = mock('client')
    client.expects(:follow).with('foo', follow: false)

    TwitterChannel.expects(:new_authorized_client).with(@channel.token, @channel.secret, TwitterChannel.consumer_key, TwitterChannel.consumer_secret).returns(client)

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret2')
    get :friendship_create, :name => @channel.name, :user => 'foo'

    assert_response :ok
  end

  test "application authenticated can't access account channel" do
    @account = Account.make! :password => 'secret'
    @application = Application.make! :account => @account, :password => 'secret2'
    @channel = TwitterChannel.make! :account => @account

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret2')
    get :friendship_create, :name => @channel.name, :user => 'foo'

    assert_response :forbidden
  end

  test "channel not found" do
    @account = Account.make! :password => 'secret'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
    get :friendship_create, :name => 'not_exists', :user => 'foo'

    assert_response :not_found
  end

  test "channel not twitter" do
    @account = Account.make! :password => 'secret'
    @channel = QstServerChannel.make! :account => @account

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
    get :friendship_create, :name => @channel.name, :user => 'foo'

    assert_response :bad_request
  end
end
