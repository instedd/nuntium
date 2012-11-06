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

class ScheduledJobsService < Service
  loop_with_sleep 60 do
    execute_once
  end

  def execute_once
    Rails.logger.debug "Executing once..."

    ScheduledJob.due_to_run.each { |job| perform_and_destroy job }
  end

  def perform_and_destroy(job)
    job.perform
  rescue Exception => e
    Rails.logger.error "#{e.message}: #{e.backtrace}"
  else
    job.destroy
  end
end
