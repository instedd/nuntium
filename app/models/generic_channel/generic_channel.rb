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

# Generic channel handler that enqueues jobs to rabbit.
# Subclasses must define job_class
module GenericChannel
  extend ActiveSupport::Concern

  included do
    after_create :create_worker_queue
    after_enabled :enable_worker_queue
    after_disabled :disable_worker_queue
    before_destroy :destroy_worker_queue
  end

  module InstanceMethods
    def handle(msg)
      Queues.publish_ao msg, create_job(msg)
    end

    def create_worker_queue
      bind_queue
      WorkerQueue.create! :queue_name => Queues.ao_queue_name_for(self), :working_group => 'fast', :ack => true, :durable => true
    end

    def worker_queue
      WorkerQueue.for_channel self
    end

    def enable_worker_queue
      worker_queue.try :enable!
    end

    def disable_worker_queue
      worker_queue.try :disable!
    end

    def destroy_worker_queue
      worker_queue.try :destroy
    end

    def bind_queue
      Queues.bind_ao self
    end
  end
end
