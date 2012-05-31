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

class ManagedProcess < ActiveRecord::Base
  belongs_to :account

  after_create :publish_start_notification
  before_destroy :publish_stop_notification

  # Both are needed, because enabled_changed? is lost in the after_update
  before_update :record_enabled_changed
  after_commit :publish_notification_if_needed, :on => :update

  def enable!
    self.enabled = true
    save!
  end

  def disable!
    self.enabled = false
    save!
  end

  def publish_start_notification
    publish_notification StartProcessJob
  end

  def publish_stop_notification
    publish_notification StopProcessJob
  end

  def publish_restart_notification
    publish_notification RestartProcessJob
  end

  def record_enabled_changed
    @enabled_changed = enabled_changed?
    true
  end

  def publish_notification_if_needed
    enabled_changed = @enabled_changed
    @enabled_changed = false

    if enabled_changed
      if enabled
        publish_start_notification
      else
        publish_stop_notification
      end
    else
      publish_restart_notification
    end
  end

  def publish_notification(clazz)
    Queues.publish_notification clazz.new(id), 'managed_processes'
  end
end
