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

module ChannelQstConfiguration
  def account
    @account ||= Account.find_by_id(@account_id)
  end

  def channel
    @channel ||= account.channels.find_by_id @channel_id
  end

  def get_url_user_and_password
    [channel.url, channel.user, channel.password]
  end

  def on_401(message)
    channel.logger.error :channel_id => channel.id, :message => message
    channel.enabled = false
    channel.save!
  end

  def on_exception(message)
    channel.logger.error :channel_id => channel.id, :message => message
  end
end
