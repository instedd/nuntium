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

module CronChannel
  extend ActiveSupport::Concern

  include CronTask::CronTaskOwner

  included do
    has_many :cron_tasks, :as => :parent, :dependent => :destroy # TODO: Tasks are not being destroyed

    after_create :create_tasks, :if => :enabled?
    after_enabled :create_tasks
    after_disabled :destroy_tasks
    before_destroy :destroy_tasks, :if => :enabled?
  end
end
