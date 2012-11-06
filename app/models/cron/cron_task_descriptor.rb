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

# Descriptor of a cron task to be executed by a cron task executor
class CronTaskDescriptor
  attr_accessor :task_id
  cattr_accessor :logger
  
  self.logger = Rails.logger

  def initialize(task_id)
    @task_id = task_id
  end
  
  def perform
    task = CronTask.find_by_id @task_id
    if not task.nil? then task.perform else logger.warn "Cannot execute descriptor for missing task with id '#{@task_id}'" end
  end
  
  def to_s
    "<CronTaskDescriptor:#{@task_id}>"
  end
end
