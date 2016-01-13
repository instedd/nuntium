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

class TwitterChannelTest < ActiveSupport::TestCase
  def setup
    @app = Application.make!
    @chan = TwitterChannel.make! application_id: @app.id, account_id: @app.account_id
  end

  include GenericChannelTest

  test "use nuntium twitter consumer key and secret when application isn't configured for new authorized client" do
    app = @chan.application
    app.twitter_consumer_key = nil
    app.twitter_consumer_secret = nil
    app.save!

    Twitter::Client.expects(:new).with(
      consumer_key: Nuntium::TwitterConsumerConfig['token'],
      consumer_secret: Nuntium::TwitterConsumerConfig['secret'],
      oauth_token: @chan.token,
      oauth_token_secret: @chan.secret,
    )

    @chan.new_authorized_client
  end

  test "use application twitter consumer key and secret if configured for new authorized client" do
    app = @chan.application
    app.twitter_consumer_key = 'foo'
    app.twitter_consumer_secret = 'bar'
    app.save!

    Twitter::Client.expects(:new).with(
      consumer_key: app.twitter_consumer_key,
      consumer_secret: app.twitter_consumer_secret,
      oauth_token: @chan.token,
      oauth_token_secret: @chan.secret,
    )

    @chan.new_authorized_client
  end

  test "use nuntium twitter consumer key and secret when application isn't configured for new client" do
    app = @chan.application
    app.twitter_consumer_key = nil
    app.twitter_consumer_secret = nil
    app.save!

    TwitterOAuth::Client.expects(:new).with(
      consumer_key: Nuntium::TwitterConsumerConfig['token'],
      consumer_secret: Nuntium::TwitterConsumerConfig['secret'],
    )

    @chan.new_client
  end

  test "use application twitter consumer key and secret if configured for new client" do
    app = @chan.application
    app.twitter_consumer_key = 'foo'
    app.twitter_consumer_secret = 'bar'
    app.save!

    TwitterOAuth::Client.expects(:new).with(
      consumer_key: app.twitter_consumer_key,
      consumer_secret: app.twitter_consumer_secret,
    )

    @chan.new_client
  end
end
