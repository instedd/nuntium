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

# Generic channel handler to manage services
# Subclasses must define:
#  - job_class
#  - service_name
module ServiceChannel
  extend ActiveSupport::Concern

  included do
    after_create :bind_queue
    after_commit :publish_start_channel, :on => :create
    after_enabled :publish_start_channel
    after_disabled :publish_stop_channel
    after_commit :publish_restart_channel, :on => :update
    before_destroy :publish_stop_channel
  end

  def handle(msg)
    Queues.publish_ao msg, create_job(msg)
  end

  def on_changed
    publish_restart_channel
  end

  def publish_start_channel
    Queues.publish_notification StartChannelJob.new(id), self.class.kind
    true
  end

  def publish_stop_channel
    Queues.publish_notification StopChannelJob.new(id), self.class.kind
    true
  end

  def publish_restart_channel
    Queues.publish_notification RestartChannelJob.new(id), self.class.kind
    true
  end

  def service
    "#{self.class.identifier}Service".constantize.new self
  end

  def has_connection?
    true
  end

  def bind_queue
    Queues.bind_ao self
  end
end
