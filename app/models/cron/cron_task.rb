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

class CronTask < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true

  validates_numericality_of :interval, :greater_than_or_equal_to => 0

  EXECUTION_TOLERANCE = 5.0

  # Gets the job to execute on this task
  def get_handler
    self.code.deserialize_job
  end

  # Sets the job to execute on this task
  def set_handler(handler)
    self.code = handler.to_yaml
  end

  # Updates last run and executes inner code if ok
  def perform
    if not self.last_run.nil? and Time.now.utc < self.last_run + self.interval - EXECUTION_TOLERANCE
      logger.warn "Dropping task '#{self.id}' with last run on #{self.last_run} and interval #{self.interval}"
      return :dropped
    end

    # If it's locked, see if the process is alive
    if !self.locked_tag.nil?
      begin
        Process.kill(0, self.locked_tag.to_i)
        # The process exists, return
        logger.warn "Dropping task '#{self.id}' with last run on #{self.last_run} and interval #{self.interval}"
        return :dropped
      rescue Errno::ESRCH => e
        # The process doesn't exist, go on
      end
    end

    begin
      self.locked_tag = Process.pid.to_s
      self.last_run = Time.now.utc
      self.save!
    rescue => err
      logger.error "Could not update last run time for task '#{self.id}': #{err}"
      return :error_saving
    end

    begin
      job = self.get_handler
      job.quota = self.interval / 2 if job.respond_to? :quota=
      result = job.perform || :success
    rescue => err
      logger.error "Error executing task '#{self.id}': #{err}"
      return :error_executing
    else
      logger.debug "Task '#{self.id}' executed successfully"
      return result
    ensure
      self.locked_tag = nil
      self.save!
    end
  end

  # Returns all tasks with next run less than current time
  def self.to_run
    where('next_run is null or next_run <= ?', Time.now.utc).all
  end

  # For every task set next run time to current time plus interval
  def self.set_next_run(tasks)
    tasks.each { |t| t.update_attribute(:next_run, Time.now.utc + t.interval) }
  end

  # Module that includes quota handling methods
  module QuotedTask
    @run_until = nil

    def quota=(quota)
      @run_until = Time.now.utc + quota
    end

    def has_quota?
      if not @run_until.nil? then Time.now.utc < @run_until else true end
    end
  end

  # Utilities module to be included by all users of tasks
  module CronTaskOwner
    # Creates a task with the specified name if it does not exist
    def create_task(name, interval, handle)
      if self.cron_tasks.find_by_name(name).nil?
        task = CronTask.new :parent => self, :interval => interval, :name => name
        task.set_handler handle
        return task.save
      end
      true
    end

    # Deletes a task with the specified name if it exists
    def drop_task(name)
      task = self.cron_tasks.find_by_name(name)
      task.destroy if not task.nil?
    end
  end
end
