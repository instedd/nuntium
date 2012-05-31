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

module ServiceChannelTest
  def test_should_enqueue_when_handling
    assert_channel_should_enqueue_ao_job @chan
  end

  def test_on_create_creates_managed_process
    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_equal @chan.account.id, proc.account_id
    assert_equal "#{@chan.kind}_daemon #{@chan.name}", proc.name
    assert_equal "service_daemon_ctl.rb start test #{@chan.id}", proc.start_command
    assert_equal "service_daemon_ctl.rb stop test #{@chan.id}", proc.stop_command
    assert_equal "service_daemon.#{@chan.id}..pid", proc.pid_file
    assert_equal "service_daemon_#{@chan.id}..log", proc.log_file
  end

  def test_on_create_binds_queue
    chan = @chan.class.make_unsaved
    Queues.expects(:bind_ao).with(chan)
    chan.save!
  end

  def test_on_destroy_deletes_managed_process
    @chan.destroy
    assert_equal 0, ManagedProcess.count
  end

  def test_on_change_touches_managed_process
    proc = mock('ManagedProcess')

    ManagedProcess.expects(:find_by_account_id_and_name).
      with(@chan.account.id, "#{@chan.kind}_daemon #{@chan.name}").
      returns(proc)
    proc.expects(:save!)

    @chan.priority = 1234
    @chan.save!
  end

  def test_on_enable_enables_managed_process
    @chan.enabled = false
    @chan.save!

    @chan.enabled = true
    @chan.save!

    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_true proc.enabled
  end

  def test_on_disable_disables_managed_process
    @chan.enabled = false
    @chan.save!

    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_false proc.enabled
  end

  def test_on_pause_disables_managed_process
    @chan.paused = true
    @chan.save!

    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_false proc.enabled
  end

  def test_on_resume_enables_managed_process
    @chan.paused = true
    @chan.save!

    @chan.paused = false
    @chan.save!

    procs = ManagedProcess.all
    assert_equal 1, procs.length
    proc = procs[0]
    assert_true proc.enabled
  end

  def test_on_account_change_touches
    proc = mock('ManagedProcess')

    ManagedProcess.expects(:find_by_account_id_and_name).
      with(@chan.account.id, "#{@chan.kind}_daemon #{@chan.name}").
      returns(proc)
    proc.expects(:save!)

    @chan.account.save!
  end

  def test_on_application_change_touches
    proc = mock('ManagedProcess')

    ManagedProcess.expects(:find_by_account_id_and_name).
      with(@chan.account.id, "#{@chan.kind}_daemon #{@chan.name}").
      returns(proc)
    proc.expects(:save!)

    Application.make :account => @chan.account
  end
end
