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

module CronDaemonRun

  # Gets tasks to run, enqueues a job for each of them and sets next run
  def cron_run
    to_run = CronTask.to_run
    to_run.each { |task| enqueue task }
  rescue => err
    Rails.logger.error "Error running scheduler: #{err}"
  else
    Rails.logger.info "Scheduler executed successfully enqueuing #{to_run.size} task(s)."
  ensure
    CronTask.set_next_run to_run if to_run
  end

  # Enqueue a descriptor for the specified task
  def enqueue(task)
    Queues.publish_cron_task CronTaskDescriptor.new(task.id)
    Rails.logger.info "Enqueued job for task '#{task.id}'"
  end

end

class CronService < Service
  include CronDaemonRun

  def initialize
    super
    Queues.bind_cron_tasks
  end

  loop_with_sleep(20) do
    cron_run
  end
end
