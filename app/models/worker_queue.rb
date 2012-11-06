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

class WorkerQueue < ActiveRecord::Base
  after_commit :publish_subscribe_notification, :on => :create
  before_destroy  :publish_unsubscribe_notification

  # Both are needed, because enabled_changed? is lost in the after_update
  before_update :record_enabled_changed
  after_commit :publish_notification_if_enabled_changed, :on => :update

  after_commit :delete_queue, :on => :destroy

  def self.for_channel(channel)
    find_by_queue_name Queues.ao_queue_name_for(channel)
  end

  def self.for_application(app)
    find_by_queue_name Queues.application_queue_name_for(app)
  end

  def self.find_each_enabled_for_working_group(working_group, &block)
    where(:working_group => working_group, :enabled => true).find_each &block
  end

  def subscribe(mq = Queues::DefaultMQ, &block)
    Queues.subscribe queue_name, ack, durable, mq, &block
  end

  def enable!
    self.enabled = true
    self.save!
  end

  def disable!
    self.enabled = false
    self.save!
  end

  private

  def publish_subscribe_notification
    Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
    true
  end

  def publish_unsubscribe_notification
    Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
    true
  end

  def record_enabled_changed
    @enabled_changed = enabled_changed?
    true
  end

  def publish_notification_if_enabled_changed
    enabled_changed = @enabled_changed
    @enabled_changed = false

    return unless enabled_changed

    if enabled
      Queues.publish_notification SubscribeToQueueJob.new(queue_name), working_group
    else
      Queues.publish_notification UnsubscribeFromQueueJob.new(queue_name), working_group
    end
  end

  def delete_queue
    Queues.delete queue_name, durable
  end
end
