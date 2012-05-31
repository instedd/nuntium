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

require 'test_helper'

class ManagedProcessTest < ActiveSupport::TestCase
  test "publish start notification on create" do
    jobs = collect_jobs
    mp = ManagedProcess.make
    assert_job jobs, StartProcessJob, mp
  end

  test "publish stop notification on destroy" do
    mp = ManagedProcess.make
    jobs = collect_jobs
    mp.destroy
    assert_job jobs, StopProcessJob, mp
  end

  # Can't test because of after_commit
  #test "publish restart notification on update" do
  #  mp = ManagedProcess.make
  #  jobs = collect_jobs
  #  mp.touch
  #  assert_job jobs, RestartProcessJob, mp
  #end

  # Can't test because of after_commit
  #test "publish stop notification on disabled" do
  #  mp = ManagedProcess.make
  #  jobs = collect_jobs
  #  mp.enabled = false
  #  mp.save!
  #  assert_job jobs, StopProcessJob, mp
  #end

  # Can't test because of after_commit
  #test "publish start notification on enabled" do
  #  mp = ManagedProcess.make :enabled => false
  #  jobs = collect_jobs
  #  mp.enabled = true
  #  mp.save!
  #  assert_job jobs, StartProcessJob, mp
  #end

  def collect_jobs
    jobs = []
    Queues.expects(:publish_notification).at_least_once.with do |job, routing_key, mq|
       jobs << job
       routing_key == 'managed_processes'
    end
    jobs
  end

  def assert_job(jobs, kind, mp)
    assert_equal 1, jobs.length
    assert_kind_of kind, jobs[0]
    assert_equal mp.id, jobs[0].id
  end

end
