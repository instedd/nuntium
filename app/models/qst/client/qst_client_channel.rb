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

class QstClientChannel < Channel
  include CronChannel

  configuration_accessor :url, :user, :password, :last_ao_guid, :last_at_guid
  validates_presence_of :url, :user, :password
  handle_password_change

  def self.title
    "QST client"
  end

  def self.default_protocol
    'sms'
  end

  def handle(msg)
    # AO Message should be queued, we just query them
  end

  def create_tasks
    create_task 'qst-client-channel-push', QST_PUSH_INTERVAL, PushQstChannelMessageJob.new(account_id, id)
    create_task 'qst-client-channel-pull', QST_PULL_INTERVAL, PullQstChannelMessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'qst-client-channel-push'
    drop_task 'qst-client-channel-pull'
  end
end
