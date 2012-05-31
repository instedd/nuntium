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

class ScheduledJobsServiceTest < ActiveSupport::TestCase
  cattr_accessor :flag

  def setup
    @@flag = 0
    @service = ScheduledJobsService.new
  end

  test "executes the only one" do
    job = ScheduledJob.create! :job => SetFlag.new(1), :run_at => Time.now

    @service.execute_once

    assert_equal 1, self.class.flag
    assert_equal 0, ScheduledJob.count
  end

  test "executes none" do
    ScheduledJob.create! :job => SetFlag.new(1), :run_at => 1.minute.from_now

    @service.execute_once

    assert_equal 0, self.class.flag
    assert_equal 1, ScheduledJob.count
  end

  test "resilient to fails" do
    ScheduledJob.create! :job => Fail.new, :run_at => Time.now

    @service.execute_once

    assert_equal 1, ScheduledJob.count
  end

  class SetFlag
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def perform
      ScheduledJobsServiceTest.flag = @value
    end
  end

  class Fail
     def perform
       raise "Oops"
     end
  end

end

