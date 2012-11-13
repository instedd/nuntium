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

class TwitterChannel < Channel
  include CronChannel
  include GenericChannel

  has_many :twitter_channel_statuses, :foreign_key => 'channel_id'

  configuration_accessor :token, :secret, :screen_name, :welcome_message

  # For when using /api/channels/:name/twitter/authorize
  configuration_accessor :authorize_token, :authorize_secret, :authorize_callback

  def self.default_protocol
    'twitter'
  end

  def self.consumer_key
    Nuntium::TwitterConsumerConfig['token']
  end

  def self.consumer_secret
    Nuntium::TwitterConsumerConfig['secret']
  end

  def self.new_client(consumer_key = self.consumer_key, consumer_secret = self.consumer_secret)
    TwitterOAuth::Client.new(
      consumer_key: consumer_key,
      consumer_secret: consumer_secret,
    )
  end

  def self.new_authorized_client(token, secret, consumer_key = self.consumer_key, consumer_secret = self.consumer_secret)
    Twitter::Client.new(
      consumer_key: consumer_key,
      consumer_secret: consumer_secret,
      oauth_token: token,
      oauth_token_secret: secret,
    )
  end

  def new_authorized_client
    self.class.new_authorized_client token, secret, consumer_key, consumer_secret
  end

  def new_client
    self.class.new_client consumer_key, consumer_secret
  end

  def consumer_key
    application && application.twitter_consumer_key.present? ? application.twitter_consumer_key : self.class.consumer_key
  end

  def consumer_secret
    application && application.twitter_consumer_secret.present? ? application.twitter_consumer_secret : self.class.consumer_secret
  end

  def authorize_url(callback_url)
    request_token = new_client.request_token oauth_callback: "#{Nuntium::TwitterConsumerConfig['callback_url']}?channel_id=#{id}"

    self.authorize_token = request_token.token
    self.authorize_secret = request_token.secret
    self.authorize_callback = callback_url
    self.save!

    request_token.authorize_url
  end

  def friendship_create(user, follow)
    new_authorized_client.follow(user, follow: follow)
  end

  def info
    screen_name
  end

  def create_tasks
    create_task 'twitter-receive', TWITTER_RECEIVE_INTERVAL, ReceiveTwitterMessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'twitter-receive'
  end
end
