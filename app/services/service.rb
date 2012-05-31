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

class Service

  def initialize
    @is_running = true

    @previous_trap = trap("TERM") do
      stop
      Thread.new do
        Thread.main.join(5)
        @previous_trap.call if @previous_trap
      end
    end
  end

  def running?
    @is_running
  end

  def logger
    Rails.logger
  end

  def stop
    @is_running = false
  end

  # Defines a start method that executes the given block and sleeps
  # sleep_seconds. Repeats this for ever. Takes care of exceptions.
  def self.loop_with_sleep(sleep_seconds, &block)
    raise 'no block given for loop_with_sleep' if not block_given?
    define_method 'start' do
      while running?
        begin
          instance_eval(&block)
        rescue Exception => err
          Rails.logger.error "Daemon failure: #{err} #{err.backtrace}"
        end
        sleep_seconds.times do
          sleep 1
          break if not running?
        end
      end
    end
  end

end
