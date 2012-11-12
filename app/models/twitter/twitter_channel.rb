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

  def self.default_protocol
    'twitter'
  end

  def self.new_oauth
    oauth = Twitter::OAuth.new Nuntium::TwitterConsumerConfig['token'], Nuntium::TwitterConsumerConfig['secret']
    oauth.set_callback_url Nuntium::TwitterConsumerConfig['callback_url']
    oauth
  end

  def self.new_client(config)
    oauth = new_oauth
    oauth.authorize_from_access config[:token], config[:secret]

    Twitter::Base.new(oauth)
  end

  def friendship_create(user, follow)
    client = self.class.new_client(configuration)
    client.friendship_create user, follow unless client.friendship_exists? user, screen_name
  end

  def info
    "#{screen_name} <a href=\"#\" onclick=\"twitter_view_rate_limit_status(#{id}); return false;\">view rate limit status</a>"
  end

  def get_rate_limit_status
    client = self.class.new_client configuration
    stat = client.rate_limit_status
    "Hourly limit: #{stat.hourly_limit}, Remaining hits for this hour: #{stat.remaining_hits}"
  end

  def create_tasks
    create_task 'twitter-receive', TWITTER_RECEIVE_INTERVAL, ReceiveTwitterMessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'twitter-receive'
  end
end
