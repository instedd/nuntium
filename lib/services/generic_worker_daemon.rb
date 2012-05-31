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

#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 3
  puts "Usage: ./generic_worker_daemon.rb <environment> <working_group> <instance_id>"
else
  start_service "generic_worker_daemon_#{ARGV[1]}_#{ARGV[2]}" do
    GenericWorkerService.new(ARGV[2], ARGV[1]).start
    EM.reactor_thread.join
  end
end
